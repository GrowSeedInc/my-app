# Research & Design Decisions

---
**Purpose**: 本ドキュメントは `admin-loan-entry` 機能の設計調査と意思決定の根拠を記録する。

---

## Summary
- **Feature**: `admin-loan-entry`
- **Discovery Scope**: Extension（既存ローン機能への管理者代理操作の追加）
- **Key Findings**:
  - `LoanService#create` は `user:` を引数に取るため、代理申請モードでは**変更なし**で流用可能
  - 直接記録モード（`active` 直接生成）のみ `LoanService#admin_direct_entry` を新規追加
  - 管理者名前空間（`Admin::` / `app/controllers/admin/`）が既存パターンとして確立されており、新コントローラはここに配置する

---

## Research Log

### 既存 LoanService の再利用可能性

- **Context**: 代理申請は「申請者 = 管理者ではなく指定ユーザー」にする必要がある
- **Findings**:
  - `LoanService#create(user:, equipment_id:, start_date:, expected_return_date:)` はすでに `user:` をパラメータで受け取る
  - コントローラ側で `current_user` の代わりに `target_user` を渡すだけで代理申請が実現できる
  - 在庫チェック・`with_lock`・`available_count` デクリメント・通知送信はすべてそのまま適用される
- **Implications**: 代理申請モードに対して `LoanService` の変更は不要

### 直接記録モードの実装方針

- **Context**: 管理者が `active` 状態の貸出を直接登録する場合、承認フローを経ない
- **Findings**:
  - 既存 `LoanService#create` は `status: :pending_approval` 固定
  - `active` 直接生成は別メソッド `admin_direct_entry` として追加するのが責務分離上適切
  - 在庫デクリメント・ロック・通知ロジックは `create` と同一であるため、プライベートメソッドで共通化できる
- **Implications**: `LoanService` に `admin_direct_entry` メソッドを追加。内部実装でロック処理を共有

### User モデルのソフトデリート非対応

- **Context**: 要件 3.1 に「discarded でないユーザー」とあるが、`User` モデルに Discard は組み込まれていない
- **Findings**: `app/models/user.rb` に `include Discard::Model` は存在しない
- **Implications**: ユーザー一覧は `User.all.order(:name)` で取得。将来的に Discard 導入された場合は `.kept` に変更

### 管理者コントローラの配置

- **Context**: 管理者専用機能の配置ルール
- **Findings**: `app/controllers/admin/dashboards_controller.rb`、`app/controllers/admin/users_controller.rb` が既存パターン
- **Implications**: 新コントローラは `Admin::LoansController`（`app/controllers/admin/loans_controller.rb`）、ルートは `namespace :admin { resources :loans, only: [:new, :create] }`

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations |
|--------|-------------|-----------|---------------------|
| A: Admin::LoansController + LoanService 拡張 | 既存 LoanService に `admin_direct_entry` を追加し、Admin コントローラから呼ぶ | 在庫ロジックの重複なし、既存パターンに完全準拠 | LoanService が若干肥大化 |
| B: AdminLoanService 新設 | 新サービスクラスに両モードのロジックを書く | 単一責務クラス | LoanService とのロジック重複リスク大 |

**選択**: Option A。既存 `LoanService` の在庫ロック・通知ロジックを完全再利用でき、重複排除できる。

---

## Design Decisions

### Decision: 単一フォーム＋モード切替

- **Context**: 代理申請と直接記録は入力項目がほぼ同じ（ユーザー・備品・日付のみ異なるのはステータス）
- **Alternatives Considered**:
  1. アクションを分ける（`new_apply`, `new_direct` など）
  2. 単一フォームにラジオボタンでモード選択
- **Selected Approach**: 単一 `new` / `create` アクションで `mode` パラメータ（`apply` / `direct`）を受け取る
- **Rationale**: UIの重複を避け、コントローラのアクション数を最小化。モード分岐はコントローラ内で1箇所のみ
- **Trade-offs**: フォームに mode ラジオボタンが必要になるが複雑度は低い

### Decision: LoanPolicy への admin_entry? 追加

- **Context**: 既存 `LoanPolicy` は `approve?` で `user.admin?` チェックを行っているが、管理者代理登録専用の権限メソッドがない
- **Selected Approach**: `LoanPolicy#admin_entry?` を追加し `user.admin?` を返す
- **Rationale**: Pundit の一元管理原則に準拠し、コントローラ内での条件分岐を排除する

---

## Risks & Mitigations

- **在庫整合性リスク**: 直接記録と代理申請が同時実行 → `with_lock` による排他制御で対応（既存パターン踏襲）
- **User 非 Discard リスク**: 退職済みユーザーが一覧に出る可能性 → 将来的に `User#active` スコープ追加を推奨、現時点は全件表示

---

## References

- 既存実装: `app/services/loan_service.rb`
- 既存実装: `app/controllers/admin/dashboards_controller.rb`
- 既存実装: `app/policies/loan_policy.rb`
