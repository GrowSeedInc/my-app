require "csv"

class EquipmentsController < ApplicationController
  include CsvImportable

  before_action :set_equipment, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Equipment
    setup_index_data
  end

  def show
    authorize @equipment
  end

  def new
    authorize Equipment
    @equipment = Equipment.new
    @category_major = nil
    @category_medium = nil
    @category_minor = nil
  end

  def create
    authorize Equipment
    result = equipment_service.create(**equipment_create_params)

    if result[:success]
      redirect_to result[:equipment], notice: "備品を登録しました"
    else
      @equipment = result[:equipment]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @equipment
    if (minor = @equipment.category)
      @category_minor  = minor
      @category_medium = minor.parent
      @category_major  = @category_medium&.parent
    else
      @category_major = nil
      @category_medium = nil
      @category_minor = nil
    end
  end

  def update
    authorize @equipment
    result = equipment_service.update(equipment: @equipment, params: equipment_update_params)

    if result[:success]
      redirect_to @equipment, notice: "備品情報を更新しました"
    else
      @equipment = result[:equipment]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @equipment
    result = equipment_service.destroy(equipment: @equipment)

    if result[:success]
      redirect_to equipments_path, notice: "備品を削除しました"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def export_csv
    authorize Equipment, :export_csv?
    scope = filtered_equipments_scope
    csv = CsvExportService.new.export_equipments(scope)
    send_data csv,
              filename: "equipments_#{Date.today.strftime('%Y%m%d')}.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_template
    authorize Equipment, :import_csv?
    headers = %w[備品名 管理番号 大分類名 中分類名 小分類名 ステータス 総数 在庫警告閾値 説明]
    csv = "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") { |c| c << headers }
    send_data csv,
              filename: "equipments_template.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_csv
    authorize Equipment, :import_csv?
    return if validate_csv_upload(params[:file], equipments_path)

    result = CsvImportService.new.import_equipments(params[:file])
    handle_csv_import_result(result, equipments_path)
  rescue ArgumentError => e
    redirect_to equipments_path, alert: e.message
  end

  private

  def setup_index_data
    @category_majors = Category.major.order(:name)

    search_result = search_service.search_equipments(
      keyword:            params[:keyword],
      category_major_id:  params[:category_major_id],
      category_medium_id: params[:category_medium_id],
      category_minor_id:  params[:category_minor_id],
      status:             params[:status],
      sort:               params[:sort],
      page:               params[:page]
    )
    @equipments = search_result.records
    @pagination = search_result

    if current_user.admin?
      equipment_ids = @equipments.map(&:id)
      @active_loans_by_equipment = Loan.active_or_overdue
                                       .where(equipment_id: equipment_ids)
                                       .includes(:user, :equipment)
                                       .group_by(&:equipment_id)
    else
      @my_active_equipment_ids = current_user.loans
                                             .active_or_overdue
                                             .pluck(:equipment_id)
    end
  end

  def filtered_equipments_scope
    scope = Equipment.kept.eager_load(category: { parent: :parent })
    if params[:keyword].present?
      p = "%#{params[:keyword]}%"
      scope = scope.where(
        "equipments.name ILIKE :p OR equipments.management_number ILIKE :p OR equipments.description ILIKE :p",
        p: p
      )
    end
    if params[:category_minor_id].present?
      scope = scope.where(category_id: params[:category_minor_id])
    elsif params[:category_medium_id].present?
      scope = scope.where(category_id: Category.minors_under_medium(params[:category_medium_id]))
    elsif params[:category_major_id].present?
      scope = scope.where(category_id: Category.minors_under_major(params[:category_major_id]))
    end
    scope = scope.where(status: params[:status]) if params[:status].present?
    order_clause = SearchService::EQUIPMENT_SORT_MAP[params[:sort]] || "equipments.created_at DESC"
    scope.order(Arel.sql(order_clause))
  end

  def set_equipment
    @equipment = Equipment.find(params[:id])
  end

  def equipment_service
    @equipment_service ||= EquipmentService.new
  end

  def search_service
    @search_service ||= SearchService.new
  end

  def equipment_create_params
    params.require(:equipment).permit(
      :name, :management_number, :total_count, :available_count,
      :description, :category_id, :status, :low_stock_threshold
    ).to_h.symbolize_keys
  end

  def equipment_update_params
    params.require(:equipment).permit(
      :name, :management_number, :total_count, :available_count,
      :description, :category_id, :status, :low_stock_threshold
    )
  end
end
