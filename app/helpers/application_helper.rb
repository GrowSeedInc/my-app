module ApplicationHelper
  def loan_status_badge_class(status)
    case status.to_s
    when "pending_approval" then "bg-yellow-100 text-yellow-800"
    when "active"           then "bg-blue-100 text-blue-800"
    when "returned"         then "bg-gray-100 text-gray-800"
    when "overdue"          then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def equipment_status_badge_class(status)
    case status.to_s
    when "available" then "bg-green-100 text-green-800"
    when "in_use"    then "bg-blue-100 text-blue-800"
    when "repair"    then "bg-yellow-100 text-yellow-800"
    when "disposed"  then "bg-gray-100 text-gray-800"
    else "bg-gray-100 text-gray-800"
    end
  end
end
