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
