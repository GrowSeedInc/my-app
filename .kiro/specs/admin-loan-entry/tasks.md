# Implementation Plan

- [x] 1. (P) LoanPolicy に管理者代理操作の認可メソッドを追加する
  - 既存の LoanPolicy に `admin_entry?` メソッドを追加し、admin ロールのユーザーのみ `true` を返す
  - ApplicationPolicy を継承した既存パターンに準拠する
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 2. (P) LoanService に active 状態の貸出を直接登録するメソッドを追加する
  - 既存の `create` メソッドと同様に、備品の有効性（ソフトデリート・ステータス）と在庫数 > 0 を検証する
  - `active` ステータスで Loan レコードを作成し、`available_count` を 1 デクリメントする
  - 排他ロックを使用してトランザクション内で在庫整合性を保証する
  - 成功時に対象ユーザーへ貸出確認メールを送信し、低在庫閾値を下回った場合はアラートを送信する
  - 戻り値は `{ success:, loan:, error:, message: }` 形式の既存パターンに準拠する
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 3. 管理者代理貸出コントローラとルートを実装する

- [x] 3.1 admin 名前空間に loans リソースのルートを追加する
  - config/routes.rb の `namespace :admin` ブロックに loans リソース（new / create のみ）を追加する
  - _Requirements: 4.1_

- [x] 3.2 Admin::LoansController の new / create アクションを実装する
  - `new` アクションでは全ユーザー一覧と貸出可能備品（available / in_use）の一覧を取得してフォームに渡す
  - `create` アクションでは `mode` パラメータに応じて代理申請（既存 LoanService#create に対象ユーザーを渡す）または直接記録（新規 admin_direct_entry）を呼び分ける
  - 認可は `LoanPolicy#admin_entry?` に委譲し、コントローラ内でのロール判定は行わない
  - 成功時は貸出一覧へリダイレクト、バリデーション失敗時は入力値を保持してフォームを再表示する
  - `loan_params` に `user_id` と `mode` を追加して strong parameters を設定する
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [x] 4. 代理貸出フォームビューを実装する
  - モードを切り替えるラジオボタン（代理申請 / 直接記録）を配置する
  - 対象ユーザーを「氏名（メールアドレス）」形式のセレクトボックスで選択できるようにする
  - 備品セレクトボックス・貸出開始日・返却予定日の入力フィールドを配置する
  - バリデーションエラー時にエラーメッセージを表示し、入力済み値を保持する
  - 既存の管理者画面レイアウトと Tailwind CSS スタイルに準拠する
  - _Requirements: 3.1, 3.2, 3.3, 5.3_

- [x] 5. テストを実装する

- [x] 5.1 (P) LoanPolicy の admin_entry? メソッドのテストを実装する
  - admin ロールのユーザーが `true` を返すことを検証する
  - member ロールのユーザーが `false` を返すことを検証する
  - _Requirements: 4.1, 4.2_

- [x] 5.2 (P) LoanService の admin_direct_entry メソッドのテストを実装する
  - 成功時に `active` ステータスの Loan が作成され `available_count` が減算されることを検証する
  - 在庫 0 の場合に `:out_of_stock` エラーを返し Loan が作成されないことを検証する
  - 無効備品（ソフトデリート済み・非貸出ステータス）の場合に `:equipment_not_available` を返すことを検証する
  - 成功時に貸出確認メールが送信されることを検証する
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 5.3 (P) Admin::LoansController のリクエストテストを実装する
  - admin ユーザーが GET /admin/loans/new にアクセスできることを検証する
  - member ユーザーのアクセスが 403 になることを検証する
  - 代理申請モードで POST 成功時に `pending_approval` の Loan が作成されることを検証する
  - 直接記録モードで POST 成功時に `active` の Loan が作成されることを検証する
  - バリデーションエラー時に 422 とフォームが返されることを検証する
  - _Requirements: 1.1, 2.1, 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_
