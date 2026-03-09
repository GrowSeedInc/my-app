class EquipmentsController < ApplicationController
  before_action :set_equipment, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Equipment
    @equipments = Equipment.kept.includes(:category).order(created_at: :desc)
  end

  def show
    authorize @equipment
  end

  def new
    authorize Equipment
    @equipment = Equipment.new
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

  private

  def set_equipment
    @equipment = Equipment.find(params[:id])
  end

  def equipment_service
    @equipment_service ||= EquipmentService.new
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
