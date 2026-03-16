class Admin::CategoriesController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    authorize Category
    result = search_service.search_categories(
      keyword: params[:keyword],
      sort:    params[:sort],
      page:    params[:page]
    )
    @categories = result.records
    @pagination = result
  end

  def new
    authorize Category
    @category = Category.new
  end

  def create
    authorize Category
    result = category_service.create(name: category_params[:name])
    if result[:success]
      redirect_to admin_categories_path, notice: "カテゴリを作成しました"
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
      redirect_to admin_categories_path, notice: "カテゴリを更新しました"
    else
      @category = result[:category]
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    result = category_service.destroy(category: @category)
    if result[:success]
      redirect_to admin_categories_path, notice: "カテゴリを削除しました"
    else
      redirect_to admin_categories_path, alert: result[:message]
    end
  end

  def export_csv
    authorize Category, :export_csv?
    csv = CsvExportService.new.export_categories(Category.order(:name))
    send_data csv,
              filename: "categories_#{Date.today.strftime('%Y%m%d')}.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_template
    authorize Category, :import_csv?
    require "csv"
    headers = %w[カテゴリ名]
    csv = "\xEF\xBB\xBF" + CSV.generate(encoding: "UTF-8") { |c| c << headers }
    send_data csv,
              filename: "categories_template.csv",
              type: "text/csv; charset=utf-8"
  end

  def import_csv
    authorize Category, :import_csv?

    file = params[:file]
    unless file.present?
      return redirect_to admin_categories_path, alert: "ファイルを選択してください"
    end
    if file.size > 5.megabytes
      return redirect_to admin_categories_path, alert: "ファイルサイズは5MB以下にしてください"
    end
    unless CsvImportService.new.csv_file?(file)
      return redirect_to admin_categories_path, alert: "CSVファイルを選択してください"
    end

    result = CsvImportService.new.import_categories(file)

    if result[:success]
      redirect_to admin_categories_path, notice: result[:message]
    else
      flash[:import_errors] = result[:errors]
      redirect_to admin_categories_path, alert: result[:message]
    end
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_service
    @category_service ||= CategoryService.new
  end

  def search_service
    @search_service ||= SearchService.new
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
