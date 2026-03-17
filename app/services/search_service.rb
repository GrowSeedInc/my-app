class SearchService
  PER_PAGE = 20

  SearchResult = Struct.new(:records, :total_count, :page, :per_page, keyword_init: true) do
    def total_pages
      [ (total_count.to_f / per_page).ceil, 1 ].max
    end

    def next_page
      page + 1 if page < total_pages
    end

    def prev_page
      page - 1 if page > 1
    end
  end

  CATEGORY_SORT_MAP = {
    "name"                 => "categories.name ASC",
    "name_desc"            => "categories.name DESC",
    "created_at"           => "categories.created_at DESC",
    "created_at_asc"       => "categories.created_at ASC",
    "equipments_count"     => "equipments_count DESC",
    "equipments_count_asc" => "equipments_count ASC"
  }.freeze

  EQUIPMENT_SORT_MAP = {
    "name"                => "equipments.name ASC",
    "name_desc"           => "equipments.name DESC",
    "category"            => "categories.name ASC NULLS LAST",
    "category_desc"       => "categories.name DESC NULLS LAST",
    "created_at"          => "equipments.created_at DESC",
    "created_at_asc"      => "equipments.created_at ASC",
    "available_count"     => "equipments.available_count DESC",
    "available_count_asc" => "equipments.available_count ASC"
  }.freeze

  # 備品を検索・フィルタ・ソートしてページネーション結果を返す
  # @return [SearchResult]
  def search_equipments(keyword: nil, category_major_id: nil, category_medium_id: nil, category_minor_id: nil, status: nil, sort: nil, page: 1)
    scope = Equipment.kept.eager_load(category: { parent: :parent })

    if keyword.present?
      pattern = "%#{keyword}%"
      scope = scope.where(
        "equipments.name ILIKE :p OR equipments.management_number ILIKE :p OR equipments.description ILIKE :p",
        p: pattern
      )
    end

    if category_minor_id.present?
      scope = scope.where(category_id: category_minor_id)
    elsif category_medium_id.present?
      scope = scope.where(category_id: Category.where(parent_id: category_medium_id).select(:id))
    elsif category_major_id.present?
      scope = scope.where(
        category_id: Category.where(
          parent_id: Category.where(parent_id: category_major_id).select(:id)
        ).select(:id)
      )
    end

    scope = scope.where(status: status) if status.present?

    order_clause = EQUIPMENT_SORT_MAP[sort] || "equipments.created_at DESC"
    scope = scope.order(Arel.sql(order_clause))

    paginate(scope, page)
  end

  # カテゴリを検索・ソートしてページネーション結果を返す
  # @return [SearchResult]
  def search_categories(keyword: nil, sort: nil, page: 1)
    base_scope = Category.all
    base_scope = base_scope.where("categories.name ILIKE ?", "%#{keyword}%") if keyword.present?

    scope = base_scope.left_joins(:equipments)
                      .group("categories.id")
                      .select("categories.*, COUNT(equipments.id) AS equipments_count")

    order_clause = CATEGORY_SORT_MAP[sort] || "categories.created_at DESC"
    scope = scope.order(Arel.sql(order_clause))

    current_page = [ page.to_i, 1 ].max
    total_count  = base_scope.count
    records      = scope.offset((current_page - 1) * PER_PAGE).limit(PER_PAGE)

    SearchResult.new(
      records:     records,
      total_count: total_count,
      page:        current_page,
      per_page:    PER_PAGE
    )
  end

  # 貸出をフィルタしてページネーション結果を返す
  # @return [SearchResult]
  def search_loans(user_id: nil, equipment_id: nil, status: nil, date_from: nil, date_to: nil, page: 1)
    scope = Loan.includes(:equipment, :user).order(created_at: :desc)

    scope = scope.where(user_id: user_id)           if user_id.present?
    scope = scope.where(equipment_id: equipment_id) if equipment_id.present?
    scope = scope.where(status: status)             if status.present?
    scope = scope.where("start_date >= ?", date_from)            if date_from.present?
    scope = scope.where("expected_return_date <= ?", date_to)    if date_to.present?

    paginate(scope, page)
  end

  private

  def paginate(scope, page)
    current_page = [ page.to_i, 1 ].max
    total_count  = scope.except(:order).count
    records      = scope.offset((current_page - 1) * PER_PAGE).limit(PER_PAGE)

    SearchResult.new(
      records:     records,
      total_count: total_count,
      page:        current_page,
      per_page:    PER_PAGE
    )
  end
end
