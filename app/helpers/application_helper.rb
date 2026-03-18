module ApplicationHelper
  # 日付を "YYYY/MM/DD" 形式にフォーマットする。nil の場合は "—" を返す。
  def format_date(date)
    date&.strftime("%Y/%m/%d") || "—"
  end

  # 日時を "YYYY年MM月DD日 HH:MM" 形式にフォーマットする。nil の場合は "—" を返す。
  def format_datetime(datetime)
    datetime&.strftime("%Y年%m月%d日 %H:%M") || "—"
  end

  LOAN_STATUS_BADGE_CLASSES = {
    "pending_approval" => "bg-yellow-100 text-yellow-800",
    "active"           => "bg-blue-100 text-blue-800",
    "returned"         => "bg-gray-100 text-gray-800",
    "overdue"          => "bg-red-100 text-red-800"
  }.freeze

  EQUIPMENT_STATUS_BADGE_CLASSES = {
    "available" => "bg-green-100 text-green-800",
    "in_use"    => "bg-blue-100 text-blue-800",
    "repair"    => "bg-yellow-100 text-yellow-800",
    "disposed"  => "bg-gray-100 text-gray-800"
  }.freeze

  def loan_status_badge_class(status)
    LOAN_STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-800")
  end

  def equipment_status_badge_class(status)
    EQUIPMENT_STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-800")
  end
end
