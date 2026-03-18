# Research & Design Decisions: category-hierarchy

---
**Purpose**: 設計フェーズの調査結果・アーキテクチャ検討・意思決定根拠を記録する。

---

## Summary
- **Feature**: `category-hierarchy`
- **Discovery Scope**: Extension（既存システムへの広範囲変更）
- **Key Findings**:
  - 既存 `categories` テーブルへの self-referential 拡張が最も変更コストが低い（FK 破壊なし）
  - Stimulus + JSON データ属性による連動セレクトは Rails 8.1 + importmap 環境で追加 gem 不要
  - PostgreSQL の NULL 扱いにより、UNIQUE 制約は親スコープごとに部分インデックスで実現する必要がある

---

## Research Log

### カテゴリ階層 DB 設計の選択

- **Context**: 大分類・中分類・小分類をどのデータ構造で表現するか
- **Sources Consulted**: Rails ガイド（self-referential associations）、PostgreSQL 部分インデックス公式ドキュメント
- **Findings**:
  - Self-referential: `parent_id uuid REFERENCES categories(id)` + `level integer` を既存テーブルに追加
  - 3 独立テーブル: `category_majors`, `category_mediums`, `category_minors` を新設し `equipments.category_id` を `category_minor_id` にリネーム
  - PostgreSQL の UNIQUE 制約は NULL 同士を区別しないため、`parent_id IS NULL` の場合はグローバル一意を、`parent_id IS NOT NULL` の場合はスコープ一意を部分インデックスで実現する
- **Implications**: Self-referential を選択した場合、`equipments.category_id` FK を変更不要で移行コストが低い。`COALESCE` を使った関数インデックスより部分インデックスの方が保守性が高い

### Stimulus 連動セレクト（Cascading Select）

- **Context**: 大分類選択→中分類リスト更新→小分類リスト更新という3段階の連動UIをどう実現するか
- **Sources Consulted**: Stimulus Handbook（Values API）、Hotwire Rails ドキュメント
- **Findings**:
  - **データ属性 JSON 方式**: ページロード時に全カテゴリ階層を JSON としてコントローラ要素の `data-value` に埋め込み、Stimulus が JavaScript でフィルタリング
    - メリット: サーバーリクエスト不要、シンプル
    - デメリット: カテゴリ数が多い場合の HTML サイズ増大
  - **AJAX/Turbo Frame 方式**: 各セレクト変更時にエンドポイント（`GET /admin/category_mediums?major_id=xxx`）を呼び出しオプションを動的取得
    - メリット: スケーラブル、初期ロード軽量
    - デメリット: JSON エンドポイント実装が必要
  - 備品管理システムのカテゴリ数は数十〜数百程度が現実的。JSON データ属性方式でも問題ない規模
- **Implications**: AJAX 方式を採用。将来的な大規模運用に対応し、かつ JSON エンドポイントが CSV インポート検証でも再利用可能

### データ移行戦略

- **Context**: 既存の categories レコード（現状は大分類相当）をどう3階層に移行するか
- **Findings**:
  - 移行マイグレーションで既存レコードを `level=0`（大分類）に設定
  - 各大分類に対して同名の中分類（`level=1`）と小分類（`level=2`）を自動生成
  - `equipment.category_id` を新しく作成した小分類 ID に更新
  - ロールバックは `down` メソッドで追加レコード削除 + カラム削除を行う
- **Implications**: 移行後の備品は必ず「`既存カテゴリ名` > `既存カテゴリ名` > `既存カテゴリ名`」という3段同名の階層に属する。運用者が後から整理する想定

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| **A: Self-referential**（選択） | 既存 `categories` テーブルに `parent_id` + `level` 追加 | FK 破壊なし、テーブル1本、既存インフラ継続利用 | depth 制約のバリデーション追加、UNIQUE 制約の設計変更が必要 | 採用決定 |
| B: 3 独立テーブル | `category_majors`, `category_mediums`, `category_minors` 新設 | 型安全、要件との直接対応 | FK 破壊的変更、ファイル大幅増加 | 却下 |
| C: Ancestry Gem | gem 追加で self-referential を管理 | 階層クエリが gem で自動化 | 新 gem 追加、Rails 8.1 + UUID 互換確認必要 | 却下（オーバーエンジニアリング） |

---

## Design Decisions

### Decision: Self-referential Category テーブル

- **Context**: 3階層カテゴリを1テーブルで表現するか複数テーブルで表現するか
- **Alternatives Considered**:
  1. Option A — `categories` テーブルに `parent_id uuid`, `level integer` を追加
  2. Option B — 3つの独立テーブルを新設し `equipments.category_id` を変更
- **Selected Approach**: Option A（Self-referential）
- **Rationale**: `equipments.category_id` FK の変更が不要で、既存テスト・シード・マイグレーションへの影響が最小。小規模システムでのオーバーエンジニアリングを避ける
- **Trade-offs**: depth バリデーション（parent は自身より1つ上の level であること）をモデルで実装する必要がある
- **Follow-up**: 4階層以上への拡張は本設計では考慮しない（Non-Goal）

### Decision: AJAX による連動セレクト

- **Context**: 3段階連動セレクトのデータ取得方式
- **Alternatives Considered**:
  1. JSON データ属性（ページロード時に全データ埋め込み）
  2. AJAX JSON エンドポイント（選択変更時にフェッチ）
- **Selected Approach**: AJAX（`GET /admin/category_mediums?major_id=xxx` 等）
- **Rationale**: カテゴリ数が増加しても対応可能な設計。JSON エンドポイントは他のCSVバリデーション等でも再利用可能
- **Trade-offs**: Stimulus コントローラの実装がデータ属性方式より複雑になる
- **Follow-up**: Stimulus の fetch + Turbo を使うか、素の fetch API を使うか実装時に決定

### Decision: 連動セレクトの初期値設定

- **Context**: 備品編集画面（既存備品は category_id が設定済み）でのフォーム初期表示
- **Selected Approach**: コントローラが `@category_minor`, `@category_medium`, `@category_major` を設定し、ビューがセレクトボックスの selected 値を明示的にセット
- **Rationale**: セレクトの依存関係を Stimulus 側で初期化するよりサーバーサイドで設定済み状態を渡す方がシンプル

### Decision: 既存 Admin::CategoriesController の扱い

- **Context**: 既存の `/admin/categories` ルート・コントローラの移行
- **Selected Approach**: 既存コントローラは3階層コントローラ（CategoryMajorsController 等）で置き換え。既存ルートはリダイレクトで互換性を維持
- **Rationale**: 既存の CSV import/export ロジックは `CsvExportService` / `CsvImportService` 側を更新することで対応

---

## Risks & Mitigations

- **FK 制約の変更**: `categories.parent_id` が自己参照 FK になる。PostgreSQL の外部キーはデフォルトで DEFERRABLE でないため、同一トランザクション内での親子同時挿入に注意 → マイグレーションでデータを順序付けて挿入（大→中→小）
- **既存テストの大規模更新**: category 関連の全テスト（spec/models, spec/services, spec/policies, spec/requests, spec/integration）が Level 指定を必要とする → 段階的に修正
- **CSV フォーマット変更の後方互換**: 既存の「カテゴリ名」単一列 CSV は旧フォーマット。移行後は3列フォーマット必須 → インポート時にカラム数でフォーマットを判別するか、明確に新フォーマットへ移行する
- **Stimulus 連動 UI のアクセシビリティ**: JavaScript 無効環境への配慮 → セレクト送信は `form` タグでラップし JS 無効でも動作するフォールバックを検討

---

## References

- Rails Guide: Self-Referential Associations — `belongs_to :parent, class_name: "Category"` パターン
- PostgreSQL Docs: Partial Indexes — `WHERE parent_id IS NULL` 形式の部分一意インデックス
- Stimulus Handbook: Values API — `data-controller-value` による JSON データバインディング
