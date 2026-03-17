class Admin::CategoryMajorsController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    authorize Category
    @majors = Category.major.includes(children: :children).order(:name)
  end

  def new
    authorize Category
    @category = Category.new(level: :major)
  end

  def create
    authorize Category
    result = category_service.create(name: category_params[:name], level: :major)
    if result[:success]
      redirect_to admin_category_majors_path, notice: "大分類を作成しました"
    else
      @category = result[:category]
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @category
  end

  def update
    authorize @category
    result = category_service.update(category: @category, params: category_params)
    if result[:success]
      redirect_to admin_category_majors_path, notice: "大分類を更新しました"
    else
      @category = result[:category]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    result = category_service.destroy(category: @category)
    if result[:success]
      redirect_to admin_category_majors_path, notice: "大分類を削除しました"
    else
      redirect_to admin_category_majors_path, alert: result[:message]
    end
  end

  def export_csv
    authorize Category, :export_csv?
    csv = CsvExportService.new.export_categories(
      Category.minor.includes(parent: :parent).order("categories.name")
    )
    send_data csv,
              filename: "categories_#{Date.today.strftime('%Y%m%d')}.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_template
    authorize Category, :import_csv?
    require "csv"
    headers = %w[大分類名 中分類名 小分類名]
    csv = "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") { |c| c << headers }
    send_data csv,
              filename: "categories_template.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_csv
    authorize Category, :import_csv?

    file = params[:file]
    unless file.present?
      return redirect_to admin_category_majors_path, alert: "ファイルを選択してください"
    end
    if file.size > 5.megabytes
      return redirect_to admin_category_majors_path, alert: "ファイルサイズは5MB以下にしてください"
    end
    unless CsvImportService.new.csv_file?(file)
      return redirect_to admin_category_majors_path, alert: "CSVファイルを選択してください"
    end

    result = CsvImportService.new.import_categories(file)

    if result[:success]
      redirect_to admin_category_majors_path, notice: result[:message]
    else
      errors = result[:errors]
      flash[:import_errors] = errors.first(50)
      flash[:import_errors_truncated] = errors.size - 50 if errors.size > 50
      redirect_to admin_category_majors_path, alert: result[:message]
    end
  rescue ArgumentError => e
    redirect_to admin_category_majors_path, alert: e.message
  end

  private

  def set_category
    @category = Category.major.find(params[:id])
  end

  def category_service
    @category_service ||= CategoryService.new
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
