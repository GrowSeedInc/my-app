# Research & Design Decisions

---
**Purpose**: CSV I/O 機能の設計判断根拠・調査ログ

---

## Summary

- **Feature**: `csv-io`
- **Discovery Scope**: Extension（既存 Rails MVC + Service + Policy アーキテクチャへの拡張）
- **Key Findings**:
  - Ruby 標準ライブラリ `csv` (3.0.9) で全要件を満たせる。外部 gem 追加不要。
  - 既存の Service Object パターン・Pundit Policy パターンをそのまま踏襲できる。
  - DB スキーマ変更不要。全操作は既存テーブルの読み書きのみ。

---

## Research Log

### Ruby 標準 CSV ライブラリの機能確認

- **Context**: 外部 gem（`smarter_csv` 等）が必要か確認
- **Findings**:
  - `CSV.parse`、`CSV.generate` でインポート・エクスポートの全操作が可能
  - BOM 付き UTF-8 は `"\xEF\xBB\xBF"` をファイル先頭に付与するだけで実現可能
  - ヘッダー行の自動マッピングは `headers: true` オプションで対応
  - Rails の `send_data` と組み合わせてファイルダウンロードが可能
- **Implications**: Gemfile 変更なし。既存の `require 'csv'` で利用可能（Rails 環境では自動 require）

### ファイルアップロードの扱い

- **Context**: CSV インポート時のファイル受信・検証方法
- **Findings**:
  - Rails の `ActionDispatch::Http::UploadedFile` でファイルを受け取り `read` で内容取得
  - `file.content_type` または拡張子チェックで CSV 形式を検証
  - `file.size` で 5MB 制限をコントローラー層で検証
- **Implications**: 追加 gem 不要。Active Storage も不要（一時ファイル処理のみ）

### `available_count` 再計算ロジック

- **Context**: 貸出履歴インポート後の在庫整合性確保
- **Findings**:
  - `active` + `overdue` ステータスの貸出数 = 貸出中数として `available_count = total_count - active_loans.count` で再計算
  - `available_count > total_count` の場合が不整合の検出条件
- **Implications**: `CsvImportService#import_loans` 完了後にトランザクション内で一括再計算

### Devise 経由での初期管理者作成

- **Context**: `/setup` で認証なしにユーザーを作成する方法
- **Findings**:
  - `User.new` + `save` が Devise モデルとして動作
  - `sign_in(user)` を呼ぶことでセッション確立可能
  - `skip_before_action :authenticate_user!` で認証スキップ
  - 初回アクセス時のみ許可するガード: `User.count > 0` ならリダイレクト
- **Implications**: `SetupsController` は `ApplicationController` を継承しつつ `skip_before_action :authenticate_user!` を適用

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | 採用 |
|--------|-------------|-----------|---------------------|------|
| 統合 CsvExportService + CsvImportService | 2 つのサービスに全エンティティのメソッドを集約 | 疎結合・既存 Service パターン踏襲 | 将来的にファイルが肥大化する可能性 | ✅ 採用 |
| エンティティ別 CSV サービス | `Equipment::CsvService` 等 | ファイル分割で小規模 | 既存の命名規則と不一致 | ❌ |
| コントローラー内に CSV ロジック | アクション内で直接 CSV 生成 | シンプル | Fat Controller、テスト困難 | ❌ |

---

## Design Decisions

### Decision: インポートを All-or-Nothing トランザクションとする

- **Context**: 部分インポートによるデータ不整合を防ぐ
- **Alternatives Considered**:
  1. 成功行のみ登録（部分インポート）
  2. 全行を検証後に全件登録（all-or-nothing）
- **Selected Approach**: 全行を事前検証し、エラーがあれば即時ロールバック
- **Rationale**: 備品・貸出の参照整合性上、部分的なデータが存在すると後続インポートが失敗するリスクがある
- **Trade-offs**: 大量データのインポートで一部エラーがあると全件やり直しが必要になる
- **Follow-up**: 大量データ（5MB 上限内）でのトランザクション性能を実装後に確認

### Decision: エクスポートは既存コントローラーに collection アクションとして追加

- **Context**: エクスポートをどのコントローラーに配置するか
- **Alternatives Considered**:
  1. 専用 `CsvController` を新設
  2. 既存コントローラーに collection アクション追加
- **Selected Approach**: 既存コントローラーへの追加（`EquipmentsController#export_csv` 等）
- **Rationale**: 検索フィルタ条件の共有が容易。既存の Pundit Policy と統合しやすい
- **Trade-offs**: コントローラーの責務が若干広がる

### Decision: インポートを admin 名前空間に配置

- **Context**: インポートアクションの配置先
- **Selected Approach**: 備品インポートは既存 `EquipmentsController` に追加（Policy で admin チェック）。カテゴリ・ユーザー・貸出は既存 Admin コントローラーに追加
- **Rationale**: 備品は既存ルートが admin 外にあるため、Policy での制御が最もシンプル

---

## Risks & Mitigations

- 大量行 CSV の同期処理によるタイムアウト — 5MB 制限で行数を抑制。将来的に ActiveJob 化を検討
- ユーザーインポート時の仮パスワード（`password123`）がセキュリティリスク — インポート完了時のフラッシュで明示的に通知し、速やかな変更を促す
- 貸出インポート時の備品名重複（同名備品が複数存在する場合）— 管理番号（`management_number`）をキーとして参照することで一意性を保証

---

## References

- Ruby CSV ライブラリ公式ドキュメント: https://ruby-doc.org/stdlib/libdoc/csv/rdoc/CSV.html
- Devise ログイン処理: `Devise::Controllers::Helpers#sign_in`
- Rails `send_data` ヘルパー: Action Controller API
