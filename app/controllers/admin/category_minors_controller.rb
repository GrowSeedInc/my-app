class Admin::CategoryMinorsController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    authorize Category
    @minors = Category.minor.includes(parent: :parent).order(:name)
  end

  def new
    authorize Category
    @category = Category.new(level: :minor)
    @major_categories = Category.major.order(:name)
    @medium_categories = Category.medium.order(:name)
  end

  def create
    authorize Category
    result = category_service.create(
      name:      category_params[:name],
      level:     :minor,
      parent_id: category_params[:parent_id]
    )
    if result[:success]
      redirect_to admin_category_minors_path, notice: "小分類を作成しました"
    else
      @category = result[:category]
      @major_categories = Category.major.order(:name)
      @medium_categories = Category.medium.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @category
    @major_categories = Category.major.order(:name)
    @medium_categories = Category.medium.where(parent_id: @category.parent&.parent_id).order(:name)
  end

  def update
    authorize @category
    result = category_service.update(category: @category, params: category_params)
    if result[:success]
      redirect_to admin_category_minors_path, notice: "小分類を更新しました"
    else
      @category = result[:category]
      @major_categories = Category.major.order(:name)
      @medium_categories = Category.medium.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    result = category_service.destroy(category: @category)
    if result[:success]
      redirect_to admin_category_minors_path, notice: "小分類を削除しました"
    else
      redirect_to admin_category_minors_path, alert: result[:message]
    end
  end

  def by_medium
    authorize Category, :by_medium?
    minors = Category.minor.where(parent_id: params[:medium_id]).order(:name)
    render json: minors.map { |c| { id: c.id, name: c.name } }
  end

  private

  def set_category
    @category = Category.minor.find(params[:id])
  end

  def category_service
    @category_service ||= CategoryService.new
  end

  def category_params
    params.require(:category).permit(:name, :parent_id)
  end
end
