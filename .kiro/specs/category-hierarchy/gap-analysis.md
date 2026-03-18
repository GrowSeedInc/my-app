# Gap Analysis: category-hierarchy

## 調査概要

既存コードベースと「カテゴリ3階層化」要件の差分を分析した。
現状はフラットな単一テーブル（`categories`）が全基盤となっており、階層構造の導入は **DBスキーマ・モデル・コントローラ・ビュー・サービス・テスト** の広範囲にわたる変更を伴う。

---

## 1. 現状調査

### 既存カテゴリ関連アセット

| レイヤー | ファイル | 現状 |
|---|---|---|
| DB | `categories` テーブル | id(UUID), name(unique), timestamps のみ |
| FK | `equipments.category_id` | `categories.id` を直接参照 |
| Model | `app/models/category.rb` | `has_many :equipments`、`validates :name, uniqueness: true` |
| Service | `app/services/category_service.rb` | `create(name:)` / `update` / `destroy` のみ |
| Controller | `app/controllers/admin/categories_controller.rb` | CRUD + CSV export/import |
| SearchService | `search_categories(keyword:, sort:, page:)` | `categories.name ILIKE` による単純検索 |
| SearchService | `search_equipments(category_id:, ...)` | `where(category_id:)` による単純フィルタ |
| CsvExportService | `export_categories` | `カテゴリ名` 単一カラムCSV |
| CsvImportService | `import_categories` | `カテゴリ名` 単一カラム、既存名はエラー |
| CsvImportService | `import_equipments` | `Category.find_by(name:)` → `category_id` 解決 |
| InventoryService | `dashboard_summary` | `group_by(&:category)` → `category.name` 表示 |
| View | `equipments/_form.html.erb` | `collection_select :category_id, Category.order(:name)` 単一セレクト |
| View | `equipments/index.html.erb` | `category_id` 単一フィルタ |
| View | `admin/categories/_form.html.erb` | `f.text_field :name` のみ |
| Routes | `admin/categories` | `resources :categories` + CSV コレクションルート |
| Tests | `spec/{models,services,policies,requests}/category*` | フラット構造ベースで全テスト済み |

### 既存コードベースの規約・制約

- **UUID主キー**: 全テーブル `pgcrypto gen_random_uuid()`
- **Service Object パターン**: コントローラ薄く、ロジックはServiceへ
- **Pundit Policy**: 全コントローラで `authorize` 呼び出し必須
- **Discard**: Equipment はソフトデリート（Category は現状ハードデリート）
- **Hotwire/Stimulus**: フロントはStimulusコントローラで動的UIを実現（既存例あり）

---

## 2. 要件フィジビリティ分析

### Requirement 1: カテゴリ階層データモデル

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| 3階層の親子関係テーブル | 単一`categories`テーブル | **Missing**: 階層構造を表すDB設計が存在しない |
| 親子バリデーション | なし | **Missing**: 親カテゴリ必須のバリデーション |
| 同一親内の名前一意性 | グローバル一意 | **Constraint**: 既存インデックス `UNIQUE(name)` は削除・再設計必要 |
| 子が存在する削除拒否 | `restrict_with_error` for equipments のみ | **Missing**: 子カテゴリに対する削除ガード |

### Requirement 2: 管理者CRUD

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| 大/中/小分類の個別CRUD | 単一 `Admin::CategoriesController` | **Missing**: 各階層のコントローラ or 汎用階層コントローラ |
| 子カテゴリ数の表示 | `equipments_count` のみ表示 | **Missing**: 中分類数・小分類数の集計 |
| 親カテゴリのセレクトボックス | なし | **Missing**: 中/小分類作成フォームでの親選択UI |
| Pundit 認可 | `CategoryPolicy` 存在 | **Constraint**: 新モデルに対応する Policy 拡張が必要 |

### Requirement 3: 備品との紐付け

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| 備品→小分類のFK | `equipment.category_id → categories` | **Missing**: `category_minor_id` への変更（破壊的変更） |
| 3段階連動セレクト | 単一 `collection_select :category_id` | **Missing**: Stimulus コントローラによる連動UI |
| 大→中→小の動的ロード | なし | **Research Needed**: Turbo Frame / Stimulus + JSON エンドポイント |

### Requirement 4: 検索・フィルタ

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| 大/中分類での上位包含フィルタ | `where(category_id:)` のみ | **Missing**: JOIN経由での上位階層フィルタロジック |
| 備品一覧の階層パス表示 | `equipment.category&.name` のみ | **Missing**: 大分類>中分類>小分類のパス表示 |
| ダッシュボードの大分類集計 | `group_by(&:category)` (現状は小分類相当) | **Missing**: 大分類単位での集計ロジック変更 |

### Requirement 5: 既存データ移行

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| 既存categoriesレコードの移行 | フラットな `categories` テーブル | **Missing**: 移行マイグレーション（既存カテゴリ→大分類として扱う） |
| `equipment.category_id` の更新 | `categories.id` 参照 | **Missing**: 新構造の小分類IDへの自動変換ロジック |
| ロールバック対応 | なし | **Missing**: `down` メソッドを持つ可逆マイグレーション |

### Requirement 6: CSV I/O

| 技術ニーズ | 現状 | ギャップ |
|---|---|---|
| カテゴリCSVの3カラム化 | `カテゴリ名` 単一カラム | **Missing**: `CsvExportService#export_categories` の3カラム対応 |
| 3カラムインポート | 単一カラム | **Missing**: `CsvImportService#import_categories` の階層対応・upsert ロジック |
| 備品CSVのカテゴリ列変更 | `カテゴリ名` で `Category.find_by(name:)` | **Missing**: 大分類>中分類>小分類のパス形式への変更 |

---

## 3. 実装アプローチの選択肢

### Option A: 既存 `categories` テーブルを Self-referential に拡張

`categories` テーブルに `parent_id UUID` と `depth INTEGER`（0=大/1=中/2=小）カラムを追加し、同一テーブルで3階層を表現。

**変更対象:**
- `categories` テーブルに `parent_id`, `depth` を追加
- `Category` モデルに `belongs_to :parent` / `has_many :children` を追加、depth バリデーション
- 既存`category_id`は末端カテゴリ（depth=2）のみ参照に制限
- `CategoryService` に親指定ロジック追加
- コントローラ・ビューで depth パラメータによる分岐

**Trade-offs:**
- ✅ テーブル1本で完結、既存FK（`equipments.category_id`）維持可
- ✅ マイグレーションが比較的シンプル（カラム追加のみ）
- ❌ depth=2 の強制バリデーションが複雑（Model/Service両方）
- ❌ 「カテゴリ名はグローバル一意」制約の廃止と `[parent_id, name]` スコープへの変更が必要
- ❌ コントローラが `depth` パラメータで分岐し煩雑になりがち

---

### Option B: 3つの独立テーブル（推奨候補）

`category_majors`, `category_mediums`, `category_minors` の3テーブルを新設。`equipments.category_minor_id` を追加（既存 `category_id` をデータ移行後に削除）。

**変更対象:**
- 新マイグレーション: `category_majors`, `category_mediums`（`major_id` FK）, `category_minors`（`medium_id` FK）
- 新モデル: `CategoryMajor`, `CategoryMedium`, `CategoryMinor`
- `Equipment`: `belongs_to :category_minor` に変更（FK変更）
- `CategoryService` を分割（または `CategoryMajorService` 等）または汎用化
- `Admin::CategoriesController` を3コントローラ（`Admin::CategoryMajorsController` 等）に分割
- 新 Policy, Factory, Spec
- SearchService, CsvExport/ImportService の全面改修

**Trade-offs:**
- ✅ 各階層が型安全・責務明確
- ✅ 要件定義（大分類/中分類/小分類）と直接対応
- ✅ 個別テスト・ポリシー定義が容易
- ❌ ファイル数が大幅増加（コントローラ×3, Policy×3, Service×3, Factory×3, Spec多数）
- ❌ FK変更（`category_id → category_minor_id`）が破壊的、全参照箇所の更新が必要
- ❌ ルート定義の大幅追加

---

### Option C: Ancestry Gem による Self-referential（階層ライブラリ活用）

`ancestry` gem を導入して `categories` テーブルを拡張。gem が深さ・祖先・子孫のクエリを提供。

**Trade-offs:**
- ✅ 階層クエリ（先祖・子孫・深さ）が gem で自動化
- ✅ テーブル1本維持
- ❌ 新 gem 追加（rubocop-rails-omakase, brakeman との整合確認が必要）
- ❌ gem の DSL 学習コスト
- **Research Needed**: `ancestry` gem の Rails 8.1 対応状況、UUID との互換性確認

---

## 4. 複雑度・リスク評価

| 項目 | 評価 | 根拠 |
|---|---|---|
| **実装工数** | **L（1〜2週間）** | DBスキーマ変更、FK破壊的変更、コントローラ・サービス・ビューの広範囲更新、データ移行、テスト更新が必要 |
| **リスク** | **High** | `equipment.category_id` の FK 破壊的変更は既存全テスト・全ビューに影響。連動セレクトUIはStimulusの設計が未確定。データ移行で既存レコードの整合性維持が必要 |

---

## 5. 設計フェーズへの引き継ぎ事項

### 推奨アプローチ
**Option B（3独立テーブル）** または **Option A（Self-referential）** の二択が現実的。要件の「各階層を個別CRUD」に最も素直に対応するのはOption B。ただし工数・ファイル増加を許容できるか設計フェーズで合意が必要。

### Research Needed（設計フェーズで調査）
1. **連動セレクトUI**: Stimulus コントローラ + Turbo Frame によるドロップダウン連動の実装パターン（JSON endpoint vs. data attributes）
2. **Option C の実現可能性**: `ancestry` gem の Rails 8.1 + UUID 主キー 対応状況
3. **既存 `categories` テーブルの廃止戦略**: Option B 採用時、既存テーブルを移行後に drop するか、互換レイヤーとして残すか
4. **CSV の後方互換**: 既存 CSV フォーマット（単一列）との互換をどう扱うか

### 主要な影響ファイル一覧（Option B の場合）

```
新規作成:
  db/migrate/xxxxxx_create_category_hierarchy.rb
  db/migrate/xxxxxx_migrate_categories_to_hierarchy.rb
  app/models/category_major.rb, category_medium.rb, category_minor.rb
  app/policies/category_major_policy.rb, category_medium_policy.rb, category_minor_policy.rb
  app/services/category_hierarchy_service.rb (または分割)
  app/controllers/admin/category_majors_controller.rb, category_mediums_controller.rb, category_minors_controller.rb
  app/views/admin/category_majors/, category_mediums/, category_minors/
  app/javascript/controllers/category_select_controller.js (Stimulus)

大幅修正:
  app/models/equipment.rb (category_id → category_minor_id)
  app/views/equipments/_form.html.erb (3段階連動セレクト)
  app/views/equipments/index.html.erb (3階層フィルタ)
  app/services/search_service.rb (category フィルタ・ソートロジック)
  app/services/csv_export_service.rb (3カラム化)
  app/services/csv_import_service.rb (3カラム + upsert ロジック)
  app/services/inventory_service.rb (dashboard_summary の大分類集計)
  config/routes.rb (ルート追加)
  spec/ (全カテゴリ関連テスト)
```
