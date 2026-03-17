# Implementation Plan

## Task Overview

| Major Task | Summary | Req Coverage |
|---|---|---|
| 1. スキーマ変更 | categories テーブルに階層カラムを追加するマイグレーション | 1.1, 1.5 |
| 2. モデル層の拡張 | Category・Equipment モデルに階層ロジックを追加 | 1.1〜1.6, 3.1, 3.5 |
| 3. CategoryService 拡張 | level・parent_id を扱える CRUD ロジックへ更新 | 1.1, 2.1〜2.6 |
| 4. 管理者カテゴリ管理画面 | 大/中/小分類の CRUD 画面・ルート・Policy を実装 | 2.1〜2.6 |
| 5. 連動セレクト UI | Stimulus コントローラと備品フォームへの組み込み | 3.2〜3.4 |
| 6. 備品検索・ダッシュボード対応 | SearchService と InventoryService を階層対応に更新 | 4.1〜4.7 |
| 7. データ移行 | 既存カテゴリを3階層に移行するマイグレーション | 5.1〜5.5 |
| 8. CSV I/O 対応 | エクスポート・インポートを3カラム形式に対応 | 6.1〜6.6 |
| 9. テスト | ユニット・統合・E2E テストの整備 | 1〜6 全要件 |

---

- [x] 1. categories テーブルに階層カラムを追加するマイグレーションを作成する

- [x] 1.1 スキーマ変更マイグレーションを実装する
  - `categories` テーブルに `parent_id`（UUID, nullable, 自己参照 FK）、`level`（integer, NOT NULL, DEFAULT 0）、`migrated_from_flat`（boolean, NOT NULL, DEFAULT false）の3カラムを追加する
  - 既存のグローバル一意インデックス `index_categories_on_name` を削除する
  - `parent_id IS NULL` の場合に `name` のグローバル一意性を保証する部分インデックス（`idx_categories_name_root`）を作成する
  - `parent_id IS NOT NULL` の場合に `(parent_id, name)` のスコープ内一意性を保証する部分インデックス（`idx_categories_name_scoped`）を作成する
  - `parent_id` の子カテゴリ取得用インデックス（`idx_categories_parent_id`）を作成する
  - `down` メソッドで3カラムとインデックスを削除し、元のグローバル一意インデックスを再作成する
  - _Requirements: 1.1, 1.5_

---

- [x] 2. Category・Equipment モデルに階層ロジックを追加する

- [x] 2.1 Category モデルに self-referential アソシエーションと level enum を追加する
  - `level` の enum（major=0, medium=1, minor=2）を定義する
  - `belongs_to :parent`（optional）と `has_many :children`（`restrict_with_error`）の self-referential アソシエーションを追加する
  - `major`・`medium`・`minor` のスコープを追加する
  - medium/minor の場合に `parent_id` を必須とするバリデーションを追加する
  - _Requirements: 1.1, 1.2_

- [x] 2.2 Category モデルにバリデーションと削除保護を追加する
  - 中分類の親は major レベルであること、小分類の親は medium レベルであることを検証する `parent_level_consistency` バリデーションを追加する
  - `name` の一意性バリデーションを `uniqueness: { scope: :parent_id }` に変更する（グローバル → スコープ内）
  - 備品に対する `dependent: :restrict_with_error` は小分類のみ意味を持つが、全 Category に設定し `category_must_be_minor` と連携させる
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2.3 (P) Equipment モデルに小分類バリデーションを追加する
  - `category_id` が存在する場合に参照先カテゴリが `level == :minor` であることを検証する `category_must_be_minor` バリデーションを追加する
  - バリデーション失敗時のエラーメッセージを「小分類（最下位カテゴリ）を選択してください」とする
  - `category_id` が NULL の場合はスキップする（`optional: true` を維持）
  - _Requirements: 3.1, 3.5_

---

- [x] 3. CategoryService を level・parent_id を扱える CRUD ロジックへ更新する

- [x] 3.1 CategoryService の create・update・destroy を階層対応にする
  - `create` メソッドに `level:` と `parent_id:` パラメータを追加し、大分類は `parent_id: nil`、中分類・小分類は親指定で作成できるようにする
  - `destroy` のエラーコードに `:has_children`（子カテゴリ存在時）を追加する
  - 戻り値のインターフェースは既存の `{ success:, category:, error:, message: }` を維持する
  - _Requirements: 1.1, 1.6, 2.1, 2.6_

---

- [x] 4. 大/中/小分類の管理者 CRUD 画面・ルート・Policy を実装する

- [x] 4.1 (P) Admin::CategoryMajorsController と大分類管理画面を実装する
  - 大分類（level=0）の index・new・create・edit・update・destroy アクションを実装する
  - index では配下の中分類数・小分類数を表示する
  - CSV export/import/import_template アクションを既存パターンで実装する（`CsvExportService`・`CsvImportService` は後のタスクで対応するため、一旦プレースホルダーでも可）
  - index・new・edit・_form の4ビューを実装する
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 4.2 (P) Admin::CategoryMediumsController と中分類管理画面を実装する
  - 中分類（level=1）の index・new・create・edit・update・destroy アクションを実装する
  - 新規作成・編集フォームに親大分類のセレクトボックスを追加する
  - `GET /admin/category_mediums?major_id=:id` で JSON `[{id:, name:}]` を返すコレクションアクション `by_major` を実装する（連動セレクト用）
  - index・new・edit・_form の4ビューを実装する
  - _Requirements: 2.1, 2.3, 2.4, 3.3_

- [x] 4.3 (P) Admin::CategoryMinorsController と小分類管理画面を実装する
  - 小分類（level=2）の index・new・create・edit・update・destroy アクションを実装する
  - 新規作成・編集フォームに親中分類（および関連大分類）のセレクトボックスを追加する
  - `GET /admin/category_minors?medium_id=:id` で JSON `[{id:, name:}]` を返すコレクションアクション `by_medium` を実装する（連動セレクト用）
  - index・new・edit・_form の4ビューを実装する
  - _Requirements: 2.1, 2.3, 2.4, 3.4_

- [x] 4.4 ルーティングと既存 CategoriesController を更新する
  - `config/routes.rb` の `resources :categories`（admin 名前空間）を `resources :category_majors`・`resources :category_mediums`・`resources :category_minors` に置き換える
  - 各コントローラに `collection` ブロックで `by_major`・`by_medium` と CSV 系アクションのルートを追加する
  - 既存の `Admin::CategoriesController` を削除し、残存するビュー・ヘルパー参照（`admin_categories_path` 等）を新パスに置き換える
  - _Requirements: 2.1_

- [x] 4.5 (P) CategoryPolicy を階層対応に拡張する
  - 既存 `CategoryPolicy` を3コントローラで共有できるよう、アクション認可の定義を確認・更新する
  - admin のみ CRUD 操作可、認証済みユーザーなら `by_major`・`by_medium` JSON エンドポイントを読み取り可とする
  - `export_csv?`・`import_csv?` は admin のみに制限する（既存パターン踏襲）
  - _Requirements: 2.6_

---

- [x] 5. Stimulus 連動セレクトコントローラと備品フォームへの組み込みを実装する

- [x] 5.1 CategorySelectController（Stimulus）を実装する
  - `app/javascript/controllers/category_select_controller.js` を新規作成する
  - `major`・`medium`・`minor` の3ターゲットと、`mediumsUrl`・`minorsUrl`・`mode`・`selectedMajor`・`selectedMedium`・`selectedMinor` の values を定義する
  - `majorChange` で `by_major` エンドポイントを fetch し、medium select のオプションを再構築、minor select をリセットする
  - `mediumChange` で `by_medium` エンドポイントを fetch し、minor select のオプションを再構築する
  - `mode: "form"` では small 未選択時に submit を抑止し、`mode: "search"` ではいずれかの選択で即フォーム送信可能にする
  - 初期値設定: `selectedMajor/Medium/Minor` values をページロード時にセレクトの選択状態に反映する
  - _Requirements: 3.2, 3.3, 3.4_

- [x] 5.2 備品登録・編集フォームに3段階連動セレクトを組み込む
  - `equipments/_form.html.erb` の単一カテゴリ `collection_select` を、大分類・中分類・小分類の3段階セレクトに置き換える
  - `data-controller="category-select"`・`mode: "form"`・各 URL values を付与する
  - 既存備品の編集時は `EquipmentsController` が `@category_minor`・`@category_medium`・`@category_major` を設定し、`selectedMajor/Medium/Minor` values としてビューに渡す
  - フォームのサブミット値は `category_id`（小分類の UUID）として送信し、既存の `equipment_params` の許可リストに変更が不要なことを確認する
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6_

---

- [x] 6. SearchService と InventoryService・備品一覧画面を階層対応に更新する

- [x] 6.1 SearchService の備品検索に階層フィルタを追加する
  - `search_equipments` のシグネチャを `category_major_id`・`category_medium_id`・`category_minor_id` の3パラメータに変更する（既存の `category_id` を廃止）
  - `category_minor_id` 指定時は直接 `WHERE category_id = ?`、`category_medium_id` 指定時は中分類経由 JOIN、`category_major_id` 指定時は大分類経由の2段 JOIN でフィルタするロジックを実装する
  - 既存の `CATEGORY_SORT_MAP` の `"category"` キーのソートSQL（`categories.name`）を小分類名ソートに維持する
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 6.2 備品一覧の検索フォームを3段階フィルタに更新する
  - `equipments/index.html.erb` のカテゴリフィルタを単一セレクトから大分類・中分類・小分類の3段階セレクトに置き換える
  - `data-category-select-mode-value="search"` を付与して検索モードで動作させる
  - `EquipmentsController#index` がフォームから `category_major_id`・`category_medium_id`・`category_minor_id` を受け取り `SearchService` に渡すよう更新する
  - 備品一覧テーブルのカテゴリ表示列を「大分類 > 中分類 > 小分類」の階層パス形式に更新する
  - _Requirements: 4.1〜4.6_

- [x] 6.3 (P) InventoryService のダッシュボード集計を大分類単位に変更する
  - `dashboard_summary` を、小分類の `parent.parent`（大分類）を辿って大分類単位で集計するロジックに変更する
  - `Equipment.kept.includes(category: { parent: :parent })` でプリロードして N+1 クエリを防ぐ
  - 大分類が未設定の備品（category_id が NULL など）はカテゴリなしとしてまとめる
  - _Requirements: 4.7_

---

- [x] 7. 既存カテゴリデータを3階層に移行するマイグレーションを実装する

- [x] 7.1 データ移行マイグレーションをマーキング方式で実装する
  - 既存の全 `Category` レコードを `level=0`（大分類）として扱い、そのまま残す
  - 各大分類に対して同名の中分類（`level=1, parent=大分類, migrated_from_flat=true`）を生成する
  - 各中分類に対して同名の小分類（`level=2, parent=中分類, migrated_from_flat=true`）を生成する
  - `Equipment.category_id` を、対応する元の大分類から新しく生成した小分類の ID に更新する
  - `down` メソッドでは `migrated_from_flat=true` のレコードを識別・削除し、`equipment.category_id` を大分類IDに戻す（ユーザー作成レコードは削除しない）
  - データ移行完了後の検証: `Equipment.kept` の全件が `Category.minor` に属する `category_id` を持つことを確認するアサーションをマイグレーション内に記述する
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

---

- [x] 8. CSV エクスポート・インポートを3カラム形式に対応させる

- [x] 8.1 (P) CsvExportService のカテゴリ出力を3カラム形式に更新する
  - `export_categories` を `Category.minor.includes(parent: :parent)` で小分類起点に呼び出し、ヘッダを `%w[大分類名 中分類名 小分類名]`、各行に `[major.name, medium.name, minor.name]` を出力するよう変更する
  - `export_equipments` のカテゴリ列を `"#{major.name} > #{medium.name} > #{minor.name}"` の階層パス形式に変更する（category が NULL の場合は空文字）
  - _Requirements: 6.1, 6.6_

- [x] 8.2 (P) CsvImportService のカテゴリインポートを3カラム形式に更新する
  - `import_categories` を `大分類名`・`中分類名`・`小分類名` の3カラム CSV を受け付けるよう変更する
  - 大分類は `find_or_create_by(name:, level: :major, parent_id: nil)` で upsert、中分類は `find_or_create_by(parent_id: major.id, name:, level: :medium)` で upsert、小分類は `find_or_create_by(parent_id: medium.id, name:, level: :minor)` で upsert する
  - バリデーションエラー（カラム不足・name 空白）は行番号付きで収集し、既存の `flash[:import_errors]` 表示パターンに乗せる
  - `import_equipments` のカテゴリ解決を `大分類名`・`中分類名`・`小分類名` の3カラムから小分類を特定するロジックに変更する（旧 `カテゴリ名` 単一カラムは廃止）
  - `Admin::CategoryMajorsController#import_template` の CSV テンプレートを3カラム形式に更新する
  - _Requirements: 6.2, 6.3, 6.4, 6.5_

---

- [x] 9. テストを整備する

- [x] 9.1 (P) Category モデルと CategoryService のユニットテストを実装する
  - `spec/models/category_spec.rb`: level enum・self-referential アソシエーション・`parent_level_consistency` バリデーション・スコープ内 name 一意性・削除制約の各ケースをテストする
  - `spec/models/equipment_spec.rb`: `category_must_be_minor` バリデーション（minor は通過、major/medium は失敗、nil は通過）をテストする
  - `spec/services/category_service_spec.rb`: 各 level での `create`・`update`・子存在時/備品存在時の `destroy` エラーをテストする
  - FactoryBot の `category` ファクトリを `level: :major` デフォルトに更新し、`:category_medium`・`:category_minor` のトレイトを追加する
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 3.1, 3.5_

- [x] 9.2 (P) 管理者コントローラの HTTP テストを実装する
  - `spec/requests/admin/category_majors_spec.rb`・`category_mediums_spec.rb`・`category_minors_spec.rb`: CRUD の正常系・バリデーションエラー系・Pundit 認可（admin/member の差異）をテストする
  - `by_major`・`by_medium` JSON エンドポイントのレスポンス形式（`[{id:, name:}]`）をテストする
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 9.3 (P) SearchService・InventoryService・CSV サービスのテストを実装する
  - `spec/services/search_service_spec.rb`: `category_major_id`・`category_medium_id`・`category_minor_id` 各フィルタで正しく備品が絞り込まれること、上位フィルタが配下の全備品を包含することをテストする
  - `spec/services/inventory_service_spec.rb`: `dashboard_summary` が大分類単位で集計されることをテストする
  - `spec/services/csv_export_service_spec.rb`: 3カラム形式・階層パス形式の出力をテストする
  - `spec/services/csv_import_service_spec.rb`: 3カラムインポート・upsert ロジック・バリデーションエラーの各ケースをテストする
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 9.4 カテゴリ階層→備品登録→検索→削除の統合テストを実装する
  - `spec/integration/category_hierarchy_spec.rb`: 大→中→小分類の作成、備品に小分類を紐付けて登録、大分類フィルタで備品が検索ヒット、小分類削除が備品存在時に失敗するフローをテストする
  - 移行マイグレーションのデータ整合性検証: 既存データで `up` を実行後、全備品が小分類を参照すること、`down` で元の状態に戻ることをテストする
  - _Requirements: 1.6, 3.1, 3.5, 4.2, 5.1, 5.3, 5.4, 5.5_

- [ ]* 9.5 備品フォームの3段階連動セレクト E2E テストを実装する
  - `spec/system/equipment_category_select_spec.rb`: 大分類選択で中分類が更新されること、中分類選択で小分類が更新されること、小分類まで選択して備品が登録できることを Capybara + Selenium でテストする
  - 検索フォームで大分類のみ選択した場合に配下の全備品が表示されることをテストする
  - _Requirements: 3.2, 3.3, 3.4, 4.2_
