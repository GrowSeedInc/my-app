class Admin::CategoryMediumsController < ApplicationController
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def new
    authorize Category
    @category = Category.new(level: :medium)
    @category.parent_id = params[:parent_id] if params[:parent_id].present?
    @major_categories = Category.major.order(:name)
  end

  def create
    authorize Category
    result = category_service.create(
      name:      category_params[:name],
      level:     :medium,
      parent_id: category_params[:parent_id]
    )
    if result[:success]
      redirect_to admin_category_majors_path, notice: "中分類を作成しました"
    else
      @category = result[:category]
      @major_categories = Category.major.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @category
    @major_categories = Category.major.order(:name)
  end

  def update
    authorize @category
    result = category_service.update(category: @category, params: category_params)
    if result[:success]
      redirect_to admin_category_majors_path, notice: "中分類を更新しました"
    else
      @category = result[:category]
      @major_categories = Category.major.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @category
    result = category_service.destroy(category: @category)
    if result[:success]
      redirect_to admin_category_majors_path, notice: "中分類を削除しました"
    else
      redirect_to admin_category_majors_path, alert: result[:message]
    end
  end

  def by_major
    authorize Category, :by_major?
    mediums = Category.medium.where(parent_id: params[:major_id]).order(:name)
    render json: mediums.map { |c| { id: c.id, name: c.name } }
  end

  private

  def set_category
    @category = Category.medium.find(params[:id])
  end

  def category_service
    @category_service ||= CategoryService.new
  end

  def category_params
    params.require(:category).permit(:name, :parent_id)
  end
end
