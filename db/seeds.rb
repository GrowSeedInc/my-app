# ============================================================
# Seed データ
# 冪等性を保証: find_or_create_by! で重複実行しても安全
# 実行: rails db:seed
# ============================================================

puts "== ユーザー =="

admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.name     = "管理者 太郎"
  u.password = "password123"
  u.role     = :admin
end
puts "  管理者: #{admin.email}"

members = [
  { name: "田中 花子", email: "hanako@example.com" },
  { name: "鈴木 一郎", email: "ichiro@example.com" },
  { name: "佐藤 美咲", email: "misaki@example.com" }
].map do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |u|
    u.name     = attrs[:name]
    u.password = "password123"
    u.role     = :member
  end
  puts "  一般: #{user.email}"
  user
end

puts "== カテゴリ =="

categories = {
  pc:       Category.find_or_create_by!(name: "PC・周辺機器"),
  mobile:   Category.find_or_create_by!(name: "モバイル機器"),
  av:       Category.find_or_create_by!(name: "AV機器"),
  furniture: Category.find_or_create_by!(name: "家具"),
  office:   Category.find_or_create_by!(name: "オフィス用品")
}
categories.each { |_, c| puts "  #{c.name}" }

puts "== 備品 =="

equipments_data = [
  # PC・周辺機器
  { name: "MacBook Pro 14インチ", management_number: "PC-001", category: categories[:pc],
    total_count: 5, available_count: 5, status: :available, low_stock_threshold: 2,
    description: "Apple M3 Pro チップ搭載。開発・デザイン業務向け。" },
  { name: "Dell モニター 27インチ", management_number: "PC-002", category: categories[:pc],
    total_count: 8, available_count: 8, status: :available, low_stock_threshold: 2,
    description: "4K対応ディスプレイ。HDMI/DisplayPort接続。" },
  { name: "Logicool ワイヤレスキーボード", management_number: "PC-003", category: categories[:pc],
    total_count: 10, available_count: 10, status: :available, low_stock_threshold: 3,
    description: "MX Keys。USB-C充電対応。" },

  # モバイル機器
  { name: "iPad Pro 12.9インチ", management_number: "MOB-001", category: categories[:mobile],
    total_count: 4, available_count: 4, status: :available, low_stock_threshold: 1,
    description: "Apple M2チップ。プレゼン・現場確認向け。" },
  { name: "iPhone 15 Pro（検証用）", management_number: "MOB-002", category: categories[:mobile],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "アプリ動作確認・デモ用。SIMなし。" },

  # AV機器
  { name: "プロジェクター（ポータブル）", management_number: "AV-001", category: categories[:av],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "ANSI 500ルーメン。HDMI/USB-C接続対応。" },
  { name: "Webカメラ 4K", management_number: "AV-002", category: categories[:av],
    total_count: 6, available_count: 6, status: :available, low_stock_threshold: 2,
    description: "リモート会議・録画向け。三脚付き。" },

  # 家具
  { name: "折りたたみテーブル", management_number: "FRN-001", category: categories[:furniture],
    total_count: 4, available_count: 4, status: :available, low_stock_threshold: 1,
    description: "会議・イベント用。幅180cm。" },
  { name: "パイプ椅子", management_number: "FRN-002", category: categories[:furniture],
    total_count: 20, available_count: 20, status: :available, low_stock_threshold: 5,
    description: "イベント・セミナー用。スタッキング可能。" },

  # オフィス用品
  { name: "ホワイトボード（大）", management_number: "OFC-001", category: categories[:office],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "180×90cm。キャスター付き。" },
  { name: "延長コード（6口）", management_number: "OFC-002", category: categories[:office],
    total_count: 8, available_count: 8, status: :available, low_stock_threshold: 2,
    description: "3m。電源タップ。" },
  { name: "デジタルカメラ", management_number: "AV-003", category: categories[:av],
    total_count: 2, available_count: 2, status: :repair, low_stock_threshold: 1,
    description: "Sony α7 IV。現在修理中。" }
]

equipments = equipments_data.map do |attrs|
  eq = Equipment.find_or_create_by!(management_number: attrs[:management_number]) do |e|
    e.name               = attrs[:name]
    e.category           = attrs[:category]
    e.total_count        = attrs[:total_count]
    e.available_count    = attrs[:available_count]
    e.status             = attrs[:status]
    e.low_stock_threshold = attrs[:low_stock_threshold]
    e.description        = attrs[:description]
  end
  puts "  #{eq.management_number}: #{eq.name}"
  eq
end

puts "== 貸出データ =="

# 返却済みの貸出（田中花子）
Loan.find_or_create_by!(
  user: members[0],
  equipment: equipments[0],   # MacBook Pro
  start_date: Date.today - 14
) do |l|
  l.expected_return_date = Date.today - 7
  l.actual_return_date   = Date.today - 8
  l.status               = :returned
end
puts "  返却済: #{members[0].name} / #{equipments[0].name}"

# 貸出中（鈴木一郎）
loan_active = Loan.find_or_create_by!(
  user: members[1],
  equipment: equipments[3],   # iPad Pro
  start_date: Date.today - 3
) do |l|
  l.expected_return_date = Date.today + 4
  l.status               = :active
end
# 在庫数を調整（既存の場合はスキップ）
if loan_active.previously_new_record?
  equipments[3].decrement!(:available_count)
end
puts "  貸出中: #{members[1].name} / #{equipments[3].name}"

# 承認待ち（佐藤美咲）
loan_pending = Loan.find_or_create_by!(
  user: members[2],
  equipment: equipments[5],   # プロジェクター
  start_date: Date.today
) do |l|
  l.expected_return_date = Date.today + 3
  l.status               = :pending_approval
end
if loan_pending.previously_new_record?
  equipments[5].decrement!(:available_count)
end
puts "  承認待ち: #{members[2].name} / #{equipments[5].name}"

# 延滞中（田中花子）
loan_overdue = Loan.find_or_create_by!(
  user: members[0],
  equipment: equipments[6],   # Webカメラ
  start_date: Date.today - 14
) do |l|
  l.expected_return_date = Date.today - 3
  l.status               = :overdue
end
if loan_overdue.previously_new_record?
  equipments[6].decrement!(:available_count)
end
puts "  延滞中: #{members[0].name} / #{equipments[6].name}"

puts ""
puts "✓ Seed データの投入が完了しました"
puts ""
puts "  管理者ログイン: admin@example.com / password123"
puts "  一般ユーザー:   hanako@example.com / password123"
puts "                  ichiro@example.com / password123"
puts "                  misaki@example.com / password123"
