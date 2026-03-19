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

# 大分類
major_it     = Category.find_or_create_by!(name: "IT機器",    level: :major, parent_id: nil)
major_office = Category.find_or_create_by!(name: "オフィス備品", level: :major, parent_id: nil)

# 中分類
medium_pc       = Category.find_or_create_by!(name: "PC・周辺機器", level: :medium, parent_id: major_it.id)
medium_mobile   = Category.find_or_create_by!(name: "モバイル機器",  level: :medium, parent_id: major_it.id)
medium_av       = Category.find_or_create_by!(name: "AV機器",       level: :medium, parent_id: major_it.id)
medium_furniture = Category.find_or_create_by!(name: "家具",          level: :medium, parent_id: major_office.id)
medium_supply   = Category.find_or_create_by!(name: "文具・備品",    level: :medium, parent_id: major_office.id)

# 小分類（備品が紐付く）
categories = {
  pc:        Category.find_or_create_by!(name: "ノートPC・モニター",        level: :minor, parent_id: medium_pc.id),
  mobile:    Category.find_or_create_by!(name: "タブレット・スマートフォン", level: :minor, parent_id: medium_mobile.id),
  av:        Category.find_or_create_by!(name: "プロジェクター・カメラ",    level: :minor, parent_id: medium_av.id),
  furniture: Category.find_or_create_by!(name: "テーブル・椅子",            level: :minor, parent_id: medium_furniture.id),
  office:    Category.find_or_create_by!(name: "ホワイトボード・電源",      level: :minor, parent_id: medium_supply.id)
}
categories.each { |_, c| puts "  #{c.parent.parent.name} > #{c.parent.name} > #{c.name}" }

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
    description: "Sony α7 IV。現在修理中。" },

  # PC・周辺機器（追加分）
  { name: "ThinkPad X1 Carbon", management_number: "PC-004", category: categories[:pc],
    total_count: 4, available_count: 4, status: :available, low_stock_threshold: 1,
    description: "Lenovo製。軽量モバイルノート。外出時の持ち運び向け。" },
  { name: "Mac mini M2", management_number: "PC-005", category: categories[:pc],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "デスクトップ作業用。モニターと組み合わせて使用。" },
  { name: "USB-Cハブ（7in1）", management_number: "PC-006", category: categories[:pc],
    total_count: 12, available_count: 12, status: :available, low_stock_threshold: 3,
    description: "HDMI・USB-A×3・SD・LAN対応。ノートPC拡張用。" },
  { name: "ワイヤレスマウス（Logicool MX Master 3）", management_number: "PC-007", category: categories[:pc],
    total_count: 10, available_count: 9, status: :available, low_stock_threshold: 3,
    description: "高精度トラッキング。USB-C充電対応。" },
  { name: "外付けSSD 1TB", management_number: "PC-008", category: categories[:pc],
    total_count: 6, available_count: 6, status: :available, low_stock_threshold: 2,
    description: "Samsung T7。USB 3.2 Gen2。高速データ転送向け。" },
  { name: "HDMIケーブル 3m", management_number: "PC-009", category: categories[:pc],
    total_count: 15, available_count: 15, status: :available, low_stock_threshold: 4,
    description: "4K60Hz対応。プロジェクター・モニター接続用。" },
  { name: "ノートPC用スタンド", management_number: "PC-010", category: categories[:pc],
    total_count: 8, available_count: 7, status: :available, low_stock_threshold: 2,
    description: "アルミ製。角度調整可能。持ち運び可能な折りたたみ式。" },
  { name: "Dell モニター 24インチ（FHD）", management_number: "PC-011", category: categories[:pc],
    total_count: 5, available_count: 5, status: :repair, low_stock_threshold: 1,
    description: "フルHD。HDMI/VGA対応。現在1台修理中。" },

  # モバイル機器（追加分）
  { name: "iPad Air（第5世代）", management_number: "MOB-003", category: categories[:mobile],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "Apple M1チップ。現場確認・プレゼン向け。" },
  { name: "Galaxy Tab S9", management_number: "MOB-004", category: categories[:mobile],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "Android端末。アプリ動作確認・デモ用。" },
  { name: "モバイルバッテリー 20000mAh", management_number: "MOB-005", category: categories[:mobile],
    total_count: 8, available_count: 8, status: :available, low_stock_threshold: 2,
    description: "Anker製。USB-C×2・USB-A×1。出張・外出時向け。" },
  { name: "ワイヤレスイヤホン（AirPods Pro）", management_number: "MOB-006", category: categories[:mobile],
    total_count: 4, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "ノイズキャンセリング対応。オンライン会議向け。" },
  { name: "スマートフォン（Android検証用）", management_number: "MOB-007", category: categories[:mobile],
    total_count: 2, available_count: 0, status: :in_use, low_stock_threshold: 1,
    description: "Pixel 8。アプリ検証用。現在全台貸出中。" },

  # AV機器（追加分）
  { name: "プロジェクタースクリーン 80インチ", management_number: "AV-004", category: categories[:av],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "三脚式。折りたたみ収納可能。会議室・イベント用。" },
  { name: "HDMIスプリッター（1入力4出力）", management_number: "AV-005", category: categories[:av],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "4K対応。複数モニターへ同時出力が必要な場面向け。" },
  { name: "USBマイク（Blue Yeti）", management_number: "AV-006", category: categories[:av],
    total_count: 4, available_count: 4, status: :available, low_stock_threshold: 1,
    description: "高音質収音。ポッドキャスト・オンライン会議向け。" },
  { name: "三脚（カメラ・スマホ兼用）", management_number: "AV-007", category: categories[:av],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "高さ最大180cm。自由雲台付き。撮影・配信向け。" },
  { name: "ビデオスイッチャー（4ch）", management_number: "AV-008", category: categories[:av],
    total_count: 1, available_count: 1, status: :available, low_stock_threshold: 1,
    description: "ATEM Mini互換。ライブ配信・録画イベント向け。" },
  { name: "ポータブルスピーカー", management_number: "AV-009", category: categories[:av],
    total_count: 4, available_count: 4, status: :available, low_stock_threshold: 1,
    description: "Bluetooth対応。イベント・会議室での音響用。" },
  { name: "照明（リングライト）", management_number: "AV-010", category: categories[:av],
    total_count: 3, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "18インチ。明るさ・色温度調整可能。オンライン会議・撮影向け。" },

  # 家具（追加分）
  { name: "会議用丸テーブル", management_number: "FRN-003", category: categories[:furniture],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "直径120cm。4〜6人用。キャスター付き。" },
  { name: "スタッキングチェア（背もたれ付き）", management_number: "FRN-004", category: categories[:furniture],
    total_count: 30, available_count: 30, status: :available, low_stock_threshold: 8,
    description: "セミナー・会議用。10脚まで積み重ね可能。" },
  { name: "ポータブルパーティション", management_number: "FRN-005", category: categories[:furniture],
    total_count: 6, available_count: 6, status: :available, low_stock_threshold: 2,
    description: "高さ180cm。間仕切り・ブース分割用。" },
  { name: "キャスター付きホワイトボード（小）", management_number: "FRN-006", category: categories[:furniture],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "90×60cm。小会議室・個人ワーク向け。" },
  { name: "受付カウンター台", management_number: "FRN-007", category: categories[:furniture],
    total_count: 2, available_count: 1, status: :available, low_stock_threshold: 1,
    description: "イベント受付用。折りたたみ式。幅120cm。" },
  { name: "プレゼン用演台", management_number: "FRN-008", category: categories[:furniture],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "高さ調整可能。セミナー・登壇者向け。" },
  { name: "折りたたみ作業台", management_number: "FRN-009", category: categories[:furniture],
    total_count: 4, available_count: 4, status: :repair, low_stock_threshold: 1,
    description: "幅90cm。軽量。現場作業・イベント設営向け。現在修理中。" },
  { name: "ディスプレイスタンド（モニター台）", management_number: "FRN-010", category: categories[:furniture],
    total_count: 6, available_count: 6, status: :available, low_stock_threshold: 2,
    description: "高さ・角度調整可能。モニター2台まで対応。" },

  # オフィス用品（追加分）
  { name: "電動シュレッダー", management_number: "OFC-003", category: categories[:office],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "A4対応。クロスカット。機密書類処理向け。" },
  { name: "ラミネーター", management_number: "OFC-004", category: categories[:office],
    total_count: 2, available_count: 2, status: :available, low_stock_threshold: 1,
    description: "A3対応。掲示物・資料のラミネート加工用。" },
  { name: "プロジェクター用リモコンポインター", management_number: "OFC-005", category: categories[:office],
    total_count: 5, available_count: 5, status: :available, low_stock_threshold: 1,
    description: "レーザーポインター付き。プレゼン向け。USB受信機内蔵。" },
  { name: "延長コード（4口・10m）", management_number: "OFC-006", category: categories[:office],
    total_count: 5, available_count: 5, status: :available, low_stock_threshold: 2,
    description: "大型イベント・会議室での電源延長向け。" },
  { name: "コードリール（20m）", management_number: "OFC-007", category: categories[:office],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "屋外イベント・遠距離電源引き回し向け。" },
  { name: "ケーブルタイ・結束バンドセット", management_number: "OFC-008", category: categories[:office],
    total_count: 10, available_count: 10, status: :available, low_stock_threshold: 3,
    description: "設営・撤収時のケーブルまとめ用。各サイズ混合。" },
  { name: "フリップチャートスタンド", management_number: "OFC-009", category: categories[:office],
    total_count: 3, available_count: 3, status: :available, low_stock_threshold: 1,
    description: "A1サイズ対応。ワークショップ・ブレスト向け。" },
  { name: "マーカーセット（ホワイトボード用）", management_number: "OFC-010", category: categories[:office],
    total_count: 10, available_count: 10, status: :available, low_stock_threshold: 3,
    description: "4色セット（黒・赤・青・緑）。ホワイトボード・フリップチャート用。" },
  { name: "デジタルタイマー", management_number: "OFC-011", category: categories[:office],
    total_count: 6, available_count: 6, status: :available, low_stock_threshold: 2,
    description: "卓上型。会議・ワークショップの時間管理向け。" },
  { name: "名札ホルダー（首掛けタイプ）", management_number: "OFC-012", category: categories[:office],
    total_count: 50, available_count: 50, status: :available, low_stock_threshold: 10,
    description: "A7サイズ。イベント・来客対応向け。" }
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
