# Implementation Plan

## csv-io 実装タスク

---

- [ ] 1. 基盤整備：Policy 拡張とルート追加

- [ ] 1.1 各 Policy に CSV 操作権限メソッドを追加する
  - `EquipmentPolicy`・`LoanPolicy`・`CategoryPolicy`・`UserPolicy` それぞれに `export_csv?` と `import_csv?` メソッドを追加する
  - `export_csv?` は全認証ユーザーに許可（`EquipmentPolicy`・`LoanPolicy`）、または管理者のみ（`CategoryPolicy`・`UserPolicy`）
  - `import_csv?` は全 Policy で管理者のみ許可
  - _Requirements: 5_

- [ ] 1.2 CSV アクションと `/setup` エンドポイントをルートに追加する
  - `resources :equipments` に `export_csv`・`import_csv`・`import_template` の collection ルートを追加する
  - `resources :loans` に `export_csv` の collection ルートを追加する
  - `namespace :admin` 配下の `categories`・`users` に `export_csv`・`import_csv`・`import_template` を追加する
  - `namespace :admin` 配下の `loans` に `import_csv`・`import_template` を追加する
  - `GET /setup`・`POST /setup` を認証不要のエンドポイントとして追加する
  - _Requirements: 1, 2, 3, 4, 6, 7, 8, 9_

---

- [ ] 2. CsvExportService 実装

- [ ] 2.1 備品・貸出履歴のエクスポートメソッドを実装する
  - UTF-8 BOM 付き CSV 文字列を生成する共通ヘルパーメソッドを実装する
  - 備品エクスポート：「備品名・管理番号・カテゴリ・ステータス・在庫数・貸出中数・説明」列を出力する
  - ソフトデリート済み備品（`discarded_at` が非 NULL）は受け取ったリレーションが除外済みであることを前提とする
  - 貸出履歴エクスポート：「備品名・貸出者名・申請日・承認日・予定返却日・実返却日・ステータス」列を出力する
  - ファイル名に出力日付を含める形式（例：`equipments_20260313.csv`）でコントローラーが `send_data` で送信できる文字列を返す
  - _Requirements: 1, 2_

- [ ] 2.2 カテゴリ・ユーザーのエクスポートメソッドを実装する
  - カテゴリエクスポート：「カテゴリ名」列を出力する
  - ユーザーエクスポート：「名前・メールアドレス・ロール・登録日」列を出力する（パスワードハッシュは含めない）
  - _Requirements: 6, 8_

---

- [ ] 3. CsvImportService 実装

- [ ] 3.1 カテゴリ・ユーザーのインポートメソッドを実装する
  - CSV ファイルが CSV 形式であることを確認するバリデーションを実装する
  - カテゴリインポート：全行を解析・検証し、名前の重複がある場合はエラー行番号と理由を返す
  - カテゴリインポート：エラーなしの場合のみトランザクション内で一括登録し、エラー時は全ロールバックする
  - ユーザーインポート：メールアドレスの重複・形式エラーを検証し、同様に All-or-nothing で登録する
  - ユーザーインポート：全ユーザーの初期パスワードを `password123` に固定する
  - 戻り値は `{ success: Boolean, count: Integer, errors: Array, message: String }` 形式とする
  - _Requirements: 8, 9_

- [ ] 3.2 備品インポートメソッドを実装する
  - CSV の各行を解析し、カテゴリ名で既存カテゴリを参照（存在しない場合はエラー）する
  - 管理番号（`management_number`）の重複・必須項目欠損・不正なステータス値を検証する
  - `available_count` は CSV から取らず `total_count` と同値で登録する（後続の貸出インポートで再計算）
  - エラーがある場合は行番号・理由一覧を返し、全行のロールバックを行う
  - _Requirements: 3_

- [ ] 3.3 貸出履歴インポートメソッドと在庫再計算を実装する
  - CSV の各行を解析し、管理番号で備品・メールアドレスでユーザーを参照する
  - 必須項目欠損・不正な日付形式・不正なステータス値・参照先不存在を検証し、エラー時は全ロールバックする
  - インポート完了後に各備品の `available_count` を `active` + `overdue` ステータスの貸出件数から再計算して更新する
  - `available_count > total_count` の不整合が検出された場合は備品名・内容を `warnings` 配列で返す
  - 戻り値に `recalculated_count`（再計算した備品数）と `warnings` を含める
  - _Requirements: 4, 10_

---

- [ ] 4. SetupsController の実装（初期管理者作成画面）

- [ ] 4.1 SetupsController とアクションを実装する
  - `ApplicationController` を継承しつつ `authenticate_user!` をスキップする設定を追加する
  - `before_action` でユーザーが1件以上存在する場合は `/users/sign_in` へリダイレクトするガードを実装する
  - `new` アクション（フォーム表示）と `create` アクション（管理者ユーザー作成・ログイン・リダイレクト）を実装する
  - 作成成功後に Devise の `sign_in` でセッションを確立してルートパスへリダイレクトする
  - _Requirements: 7_

- [ ] 4.2 初期セットアップビューを実装する
  - 名前・メールアドレス・パスワード・パスワード確認の入力フォームを実装する
  - バリデーションエラー時にフィールドごとのエラーメッセージを表示する
  - 送信後にユーザー存在チェックを経由するため、二重送信ガードを適用する
  - _Requirements: 7_

---

- [ ] 5. 備品 CSV エクスポート・インポート機能

- [ ] 5.1 (P) EquipmentsController に CSV アクションを追加する
  - `export_csv` アクション：`authorize Equipment, :export_csv?` を呼び、現在の検索フィルタ済みリレーションを `CsvExportService` に渡して `send_data` でダウンロードさせる
  - `import_template` アクション：備品インポート用テンプレート CSV をダウンロードさせる
  - `import_csv` アクション：`authorize Equipment, :import_csv?` を呼び、ファイルサイズ（5MB 以下）・形式チェック後に `CsvImportService` を呼び出す
  - インポート成功時は登録件数のフラッシュを表示してリダイレクト、失敗時はエラー一覧を表示する
  - _Requirements: 1, 3, 5_

- [ ] 5.2 (P) 備品一覧ビューに CSV ダウンロードボタンとインポートフォームを追加する
  - 備品一覧画面に「CSV ダウンロード」ボタンを追加し、現在のフィルタパラメータを引き継ぐリンクにする
  - 管理者向けにインポートファイル選択フォームとテンプレートダウンロードリンクを追加する
  - インポートエラー時にエラー一覧テーブル（行番号・理由）を表示するエリアを追加する
  - _Requirements: 1, 3_

---

- [ ] 6. 貸出履歴 CSV エクスポート・インポート機能

- [ ] 6.1 (P) LoansController・Admin::LoansController に CSV アクションを追加する
  - `LoansController#export_csv`：管理者は全件・一般ユーザーは自分の貸出のみのリレーションを `CsvExportService` に渡す
  - `Admin::LoansController#import_template`・`#import_csv`：貸出履歴テンプレートのダウンロードとインポート処理を実装する
  - インポート完了後のフラッシュに在庫再計算件数と警告を含める
  - _Requirements: 2, 4, 5_

- [ ] 6.2 (P) 貸出一覧ビューに CSV ダウンロードボタンとインポートフォームを追加する
  - 貸出一覧画面に「CSV ダウンロード」ボタンを追加する（一般ユーザーは自分のデータのみが対象であることを表示する）
  - 管理者向けページにインポートフォームとテンプレートダウンロードリンクを追加する
  - _Requirements: 2, 4_

---

- [ ] 7. カテゴリ CSV エクスポート・インポート機能

- [ ] 7.1 (P) Admin::CategoriesController に CSV アクションを追加する
  - `export_csv`・`import_template`・`import_csv` アクションを追加し、`CsvExportService`・`CsvImportService` を呼び出す
  - インポート成功・失敗時のフラッシュ表示とエラー一覧表示を実装する
  - _Requirements: 8, 5_

- [ ] 7.2 (P) カテゴリ管理ビューに CSV ダウンロードボタンとインポートフォームを追加する
  - カテゴリ一覧画面に「CSV ダウンロード」ボタン・インポートフォーム・テンプレートダウンロードリンクを追加する
  - _Requirements: 8_

---

- [ ] 8. ユーザー CSV エクスポート・インポート機能

- [ ] 8.1 (P) Admin::UsersController に CSV アクションを追加する
  - `export_csv`・`import_template`・`import_csv` アクションを追加する
  - インポート完了時のフラッシュに「初期パスワード: password123」を明示する
  - _Requirements: 6, 9, 5_

- [ ] 8.2 (P) ユーザー管理ビューに CSV ダウンロードボタンとインポートフォームを追加する
  - ユーザー一覧画面に「CSV ダウンロード」ボタン・インポートフォーム・テンプレートダウンロードリンクを追加する
  - インポート後に「初期パスワードの変更を促す」注記をビューに表示する
  - _Requirements: 6, 9_

---

- [ ] 9. 移行ガイドと在庫再計算結果表示の実装
  - 管理者向けのデータ移行案内ページまたは管理者ダッシュボードに推奨インポート順序（カテゴリ → ユーザー → 備品 → 貸出履歴）を明示するセクションを追加する
  - 貸出履歴インポート完了後のフラッシュメッセージに在庫再計算結果（更新備品数・警告件数）を含める（Task 6.1 の一部として実装済みの場合はビュー側の整合のみ確認する）
  - `available_count > total_count` の不整合警告が存在する場合は、備品管理画面で視覚的に区別して表示する
  - _Requirements: 10_

---

- [ ] 10. テスト

- [ ] 10.1 (P) CsvExportService のユニットテストを実装する
  - 備品・貸出・カテゴリ・ユーザーの各エクスポートメソッドについて、CSV ヘッダー・値・BOM 付与を検証する
  - ソフトデリート済み備品がエクスポートに含まれないことを確認する
  - パスワードハッシュがユーザー CSV に含まれないことを確認する
  - _Requirements: 1, 2, 6, 8_

- [ ] 10.2 (P) CsvImportService のユニットテストを実装する
  - カテゴリ・ユーザー・備品・貸出履歴の正常インポート時のレコード数・戻り値を検証する
  - バリデーションエラー時に全ロールバックされ `errors` 配列にエラー情報が含まれることを確認する
  - 貸出履歴インポート後の `available_count` 再計算が正確に行われることを確認する
  - `available_count > total_count` の不整合が `warnings` に含まれることを確認する
  - _Requirements: 3, 4, 8, 9, 10_

- [ ] 10.3 (P) Policy 拡張と SetupsController の統合テストを実装する
  - 各 Policy の `export_csv?`・`import_csv?` を admin / member ロールで検証する
  - SetupsController の `new`・`create` アクションについて、ユーザー0件時・存在時それぞれの挙動を検証する
  - _Requirements: 5, 7_

- [ ] 10.4 移行フローの統合テストを実装する
  - カテゴリ → ユーザー → 備品 → 貸出履歴の順でインポートした後、在庫数が正確であることをエンドツーエンドで検証する
  - 各エクスポートアクションが `Content-Type: text/csv` の正しいレスポンスを返すことを確認する
  - 一般ユーザーが管理者専用インポートエンドポイントにアクセスしたとき 403 が返ることを確認する
  - 一般ユーザーの貸出エクスポートに他ユーザーのデータが含まれないことを確認する
  - _Requirements: 1, 2, 3, 4, 5, 6, 8, 9, 10_
