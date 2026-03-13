# Research & Design Decisions

---
**Purpose**: カテゴリCRUD機能の設計調査・判断根拠を記録する。

---

## Summary
- **Feature**: `category-crud`
- **Discovery Scope**: Extension（既存adminネームスペースへのCRUD追加）
- **Key Findings**:
  - `categories` テーブルは既に存在しており、マイグレーション不要
  - `Admin::UsersController` / `UserService` / `UserPolicy` のパターンをそのまま踏襲できる
  - `SearchService` に `search_categories` メソッドを追加することで検索・ソート・ページネーションを統一できる
  - 備品数での並び替えには `LEFT JOIN + GROUP BY` が必要（N+1回避・SQL集計）

## Research Log

### 既存テーブル・モデル確認
- **Context**: マイグレーション要否を確認
- **Findings**:
  - `categories` テーブル構造: `id (uuid, PK)`, `name (string, NOT NULL, UNIQUE INDEX)`, `created_at`, `updated_at`
  - `Category` モデル: `has_many :equipments, dependent: :restrict_with_error`、`validates :name, presence: true, uniqueness: true`
- **Implications**: 新規マイグレーション不要。削除保護はモデル側の `restrict_with_error` で既に実装済み。

### Admin CRUD パターン分析
- **Context**: 実装パターンの統一性確認
- **Findings**:
  - `Admin::UsersController` → Service → Policy の三層構造
  - Controller は `authorize` を各アクションで呼び出し
  - Service は `{ success:, record:, error:, message: }` ハッシュを返す
  - Policy は全メソッドが `user.admin?` を返す単純パターン
- **Implications**: `Admin::CategoriesController` / `CategoryService` / `CategoryPolicy` をそれぞれ同パターンで実装する

### SearchService 拡張分析
- **Context**: 検索・ソート機能の実装方針
- **Findings**:
  - `search_equipments` は `EQUIPMENT_SORT_MAP` 定数 + キーワード部分一致 + ページネーションの組み合わせ
  - `SearchResult` 構造体は共有済み（`paginate` プライベートメソッド）
  - 備品数ソートは SQL の `COUNT(equipments.id)` を使う必要がある
- **Implications**: `CATEGORY_SORT_MAP` 定数と `search_categories` メソッドを `SearchService` に追加する

### 備品数の取得・ソート方法
- **Context**: 一覧表示と備品数ソートを同時に実現する方法
- **Findings**:
  - `left_joins(:equipments).group('categories.id').select('categories.*, COUNT(equipments.id) AS equipments_count')` で SQL 集計可能
  - `Arel.sql` でホワイトリスト済みの ORDER 句を注入するパターンは既存コードに存在する
- **Implications**: ソートキー `equipments_count` / `equipments_count_asc` を SORT_MAP に定義し、`Arel.sql` で安全に注入する

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Admin::CategoriesController + CategoryService | 既存 Users パターンを踏襲 | 一貫性・学習コスト低 | なし | 採用 |
| 直接 Controller で ActiveRecord 操作 | Service 省略 | コード量削減 | 既存パターンとの乖離 | 不採用 |
| SearchService 拡張 | search_categories を既存 SearchService に追加 | 共通ページネーション活用 | SearchService が肥大化する可能性 | 採用（カテゴリ件数は少ないため許容） |

## Design Decisions

### Decision: CategoryService の責務範囲
- **Context**: 削除時の保護エラーをどこで捕捉するか
- **Alternatives Considered**:
  1. モデルの `restrict_with_error` エラーをコントローラーで直接捕捉
  2. CategoryService の `destroy` メソッド内で捕捉してハッシュで返す
- **Selected Approach**: Option 2 — CategoryService が `ActiveRecord::DeleteRestrictionError` を rescue し、統一インターフェースで返す
- **Rationale**: UsersService パターンとの一貫性。コントローラーをシンプルに保つ。
- **Trade-offs**: Service 層に例外ハンドリングが入るが、既存 UserService も同様

### Decision: ページネーションの要否
- **Context**: カテゴリ件数は運用上数十件程度と想定される
- **Selected Approach**: SearchService 経由でページネーション機構は組み込むが、PER_PAGE=20 で1ページ内に収まる想定
- **Rationale**: SearchService の共通 paginate を使うため追加コストなし。将来の件数増加にも対応可能。

## Risks & Mitigations
- `equipments_count` 仮想カラムを ORDER 句で使う際に SQL インジェクションのリスク → `Arel.sql` + ホワイトリスト定数 (`CATEGORY_SORT_MAP`) で完全に防止
- `restrict_with_error` が発生するタイミングのテスト漏れ → CategoryService spec で備品紐づきカテゴリの削除テストを必須とする
