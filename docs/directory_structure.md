# ディレクトリ構造

## 概要

備品管理システム（my-app）のディレクトリ構造を示します。
対象：ルート直下の全ディレクトリおよびファイル（隠しファイル含む、`tmp` / `log` / `storage` 除く）

---

## ツリー構造

```
my-app/
├── .claude/                                  # Claude Code設定・カスタムコマンド
│   └── commands/
│       └── kiro/                             # Kiro SDD スラッシュコマンド定義
│           ├── spec-design.md
│           ├── spec-impl.md
│           ├── spec-init.md
│           ├── spec-requirements.md
│           ├── spec-status.md
│           ├── spec-tasks.md
│           ├── steering-custom.md
│           ├── steering.md
│           ├── validate-design.md
│           ├── validate-gap.md
│           └── validate-impl.md
├── .devcontainer/                            # 開発コンテナ設定
│   ├── compose.yaml
│   ├── devcontainer.json
│   └── Dockerfile
├── .git/                                     # Gitリポジトリ管理（自動生成）
├── .github/                                  # GitHub設定
│   ├── workflows/
│   │   └── ci.yml                            # GitHub Actions CI設定
│   └── dependabot.yml                        # Dependabot自動更新設定
├── .kamal/                                   # Kamalデプロイ設定
│   ├── hooks/                                # デプロイライフサイクルフック（sample）
│   │   ├── docker-setup.sample
│   │   ├── post-app-boot.sample
│   │   ├── post-deploy.sample
│   │   ├── post-proxy-reboot.sample
│   │   ├── pre-app-boot.sample
│   │   ├── pre-build.sample
│   │   ├── pre-connect.sample
│   │   ├── pre-deploy.sample
│   │   └── pre-proxy-reboot.sample
│   └── secrets
├── .kiro/                                    # Kiro Spec-Driven Development設定
│   ├── settings/
│   │   ├── rules/                            # AI開発ルール定義
│   │   │   ├── design-discovery-full.md
│   │   │   ├── design-discovery-light.md
│   │   │   ├── design-principles.md
│   │   │   ├── design-review.md
│   │   │   ├── ears-format.md
│   │   │   ├── gap-analysis.md
│   │   │   ├── steering-principles.md
│   │   │   ├── tasks-generation.md
│   │   │   └── tasks-parallel-analysis.md
│   │   └── templates/                        # 仕様書・ステアリングテンプレート
│   │       ├── specs/
│   │       │   ├── design.md
│   │       │   ├── init.json
│   │       │   ├── requirements-init.md
│   │       │   ├── requirements.md
│   │       │   ├── research.md
│   │       │   └── tasks.md
│   │       ├── steering/
│   │       │   ├── product.md
│   │       │   ├── structure.md
│   │       │   └── tech.md
│   │       └── steering-custom/
│   │           ├── api-standards.md
│   │           ├── authentication.md
│   │           ├── database.md
│   │           ├── deployment.md
│   │           ├── error-handling.md
│   │           ├── security.md
│   │           └── testing.md
│   └── specs/
│       └── equipment-management/             # 備品管理機能仕様（アクティブ）
│           ├── design.md
│           ├── requirements.md
│           ├── research.md
│           ├── spec.json
│           └── tasks.md
├── .ruby-lsp/                                # Ruby LSPキャッシュ・設定
├── .serena/                                  # Serena MCP設定
├── .dockerignore
├── .gitattributes
├── .gitignore
├── .rubocop.yml                              # RuboCop静的解析設定
├── .ruby-version                             # Rubyバージョン指定
├── app/                                      # アプリケーションのメインコード
│   ├── assets/                               # 静的アセット
│   │   ├── builds/                           # ビルド済みアセット出力（Tailwind CSS）
│   │   ├── images/                           # 画像ファイル
│   │   ├── stylesheets/
│   │   │   └── application.css
│   │   └── tailwind/
│   │       └── application.css               # Tailwind CSSソース
│   ├── controllers/                          # コントローラー
│   │   ├── admin/                            # 管理者向けコントローラー
│   │   │   ├── dashboards_controller.rb
│   │   │   └── users_controller.rb
│   │   ├── concerns/                         # コントローラー共通モジュール
│   │   ├── application_controller.rb
│   │   ├── equipments_controller.rb
│   │   ├── loans_controller.rb
│   │   └── mypages_controller.rb
│   ├── helpers/                              # ビューヘルパー
│   │   └── application_helper.rb
│   ├── javascript/                           # JavaScriptソース
│   │   ├── controllers/                      # Stimulusコントローラー
│   │   │   ├── application.js
│   │   │   ├── hello_controller.js
│   │   │   └── index.js
│   │   └── application.js
│   ├── jobs/                                 # バックグラウンドジョブ
│   │   ├── application_job.rb
│   │   └── overdue_check_job.rb              # 延滞チェックジョブ
│   ├── mailers/                              # メーラー
│   │   ├── application_mailer.rb
│   │   └── loan_mailer.rb                    # 貸出通知メーラー
│   ├── models/                               # モデル
│   │   ├── concerns/                         # モデル共通モジュール
│   │   ├── application_record.rb
│   │   ├── category.rb
│   │   ├── equipment.rb
│   │   ├── loan.rb
│   │   └── user.rb
│   ├── policies/                             # Pundit認可ポリシー
│   │   ├── application_policy.rb
│   │   ├── dashboard_policy.rb
│   │   ├── equipment_policy.rb
│   │   ├── loan_policy.rb
│   │   └── user_policy.rb
│   ├── services/                             # ビジネスロジックサービス
│   │   ├── equipment_service.rb              # 備品登録・編集・削除
│   │   ├── inventory_service.rb              # 備品ステータス管理
│   │   ├── loan_service.rb                   # 貸出申請・承認
│   │   ├── notification_service.rb           # 通知処理
│   │   ├── return_service.rb                 # 返却処理
│   │   ├── search_service.rb                 # 検索・フィルタ
│   │   └── user_service.rb                   # ユーザー管理
│   └── views/                                # ビュー（テンプレート）
│       ├── admin/
│       │   ├── dashboards/
│       │   │   └── show.html.erb             # 管理者ダッシュボード
│       │   └── users/
│       │       ├── _form.html.erb
│       │       ├── edit.html.erb
│       │       ├── index.html.erb
│       │       └── new.html.erb
│       ├── devise/                           # Devise認証ビュー
│       │   ├── registrations/
│       │   │   ├── edit.html.erb
│       │   │   └── new.html.erb
│       │   └── sessions/
│       │       └── new.html.erb
│       ├── equipments/                       # 備品管理ビュー
│       │   ├── _form.html.erb
│       │   ├── edit.html.erb
│       │   ├── index.html.erb
│       │   ├── new.html.erb
│       │   └── show.html.erb
│       ├── layouts/                          # レイアウトテンプレート
│       │   ├── application.html.erb
│       │   ├── mailer.html.erb
│       │   └── mailer.text.erb
│       ├── loan_mailer/                      # 貸出メール本文
│       │   ├── loan_confirmation.html.erb
│       │   ├── loan_confirmation.text.erb
│       │   ├── low_stock_alert.html.erb
│       │   ├── low_stock_alert.text.erb
│       │   ├── overdue_alert.html.erb
│       │   └── overdue_alert.text.erb
│       ├── loans/                            # 貸出管理ビュー
│       │   ├── _form.html.erb
│       │   ├── index.html.erb
│       │   └── new.html.erb
│       ├── mypages/                          # マイページビュー
│       │   └── show.html.erb
│       └── pwa/                              # PWA関連
│           ├── manifest.json.erb
│           └── service-worker.js
├── bin/                                      # 実行スクリプト
│   ├── brakeman
│   ├── bundler-audit
│   ├── ci
│   ├── dev
│   ├── docker-entrypoint
│   ├── importmap
│   ├── jobs
│   ├── kamal
│   ├── rails
│   ├── rake
│   ├── render-build.sh
│   ├── rubocop
│   ├── setup
│   └── thrust
├── config/                                   # アプリケーション設定
│   ├── environments/                         # 環境別設定
│   │   ├── development.rb
│   │   ├── production.rb
│   │   └── test.rb
│   ├── initializers/                         # 起動時初期化スクリプト
│   │   ├── assets.rb
│   │   ├── content_security_policy.rb
│   │   ├── devise.rb
│   │   ├── filter_parameter_logging.rb
│   │   └── inflections.rb                   # equipment複数形設定
│   ├── locales/                              # i18n国際化ファイル
│   │   ├── devise.en.yml
│   │   ├── devise.ja.yml
│   │   ├── en.yml
│   │   └── ja.yml
│   ├── application.rb
│   ├── boot.rb
│   ├── bundler-audit.yml
│   ├── cable.yml
│   ├── cache.yml
│   ├── ci.rb
│   ├── credentials.yml.enc
│   ├── database.yml
│   ├── deploy.yml
│   ├── environment.rb
│   ├── importmap.rb
│   ├── master.key
│   ├── puma.rb
│   ├── queue.yml
│   ├── recurring.yml
│   ├── routes.rb
│   ├── schedule.rb                           # Wheneverスケジュール設定
│   └── storage.yml
├── db/                                       # データベース関連
│   ├── migrate/                              # マイグレーションファイル
│   │   ├── 20260309000001_enable_pgcrypto.rb
│   │   ├── 20260309000002_devise_create_users.rb
│   │   ├── 20260309000003_add_role_to_users.rb
│   │   ├── 20260309020000_create_categories.rb
│   │   ├── 20260309030000_create_equipments.rb
│   │   ├── 20260309040000_create_loans.rb
│   │   └── 20260309050000_add_name_to_users.rb
│   ├── cable_schema.rb
│   ├── cache_schema.rb
│   ├── queue_schema.rb
│   ├── schema.rb
│   └── seeds.rb
├── docs/                                     # プロジェクトドキュメント
│   ├── api-schema.yaml                       # API スキーマ定義
│   ├── class_diagram.puml                    # クラス図
│   ├── directory_structure.csv               # ディレクトリ構造（CSV）
│   ├── directory_structure.md                # ディレクトリ構造（本ファイル）
│   ├── er_diagram.md                         # ER図
│   ├── screen_list.csv                       # 画面一覧
│   ├── sequence_diagram.puml                 # シーケンス図
│   ├── table_definitions.md                  # テーブル定義書
│   └── wbs.csv                               # WBS
├── lib/                                      # 独自ライブラリ
│   └── tasks/                                # カスタムRakeタスク
├── public/                                   # 静的公開ファイル
│   ├── 400.html
│   ├── 404.html
│   ├── 406-unsupported-browser.html
│   ├── 422.html
│   ├── 500.html
│   ├── icon.png
│   ├── icon.svg
│   └── robots.txt
├── script/                                   # 開発・運用補助スクリプト
├── spec/                                     # RSpecテスト
│   ├── factories/                            # FactoryBotファクトリ
│   │   ├── categories.rb
│   │   ├── equipments.rb
│   │   ├── loans.rb
│   │   └── users.rb
│   ├── integration/                          # 統合テスト
│   │   ├── auth_authz_flow_spec.rb
│   │   ├── equipment_search_spec.rb
│   │   └── loan_lifecycle_spec.rb
│   ├── jobs/                                 # ジョブテスト
│   │   └── overdue_check_job_spec.rb
│   ├── mailers/                              # メーラーテスト
│   │   └── loan_mailer_spec.rb
│   ├── models/                               # モデルテスト
│   │   ├── category_spec.rb
│   │   ├── equipment_spec.rb
│   │   ├── loan_spec.rb
│   │   └── user_spec.rb
│   ├── policies/                             # Punditポリシーテスト
│   │   ├── equipment_policy_spec.rb
│   │   ├── loan_policy_spec.rb
│   │   └── user_policy_spec.rb
│   ├── requests/                             # リクエストスペック
│   │   ├── admin/
│   │   │   ├── dashboard_spec.rb
│   │   │   └── users_spec.rb
│   │   ├── authentication_spec.rb
│   │   ├── equipments_spec.rb
│   │   ├── loans_return_spec.rb
│   │   ├── loans_spec.rb
│   │   ├── mypage_spec.rb
│   │   └── password_change_spec.rb
│   ├── services/                             # サービステスト
│   │   ├── equipment_service_spec.rb
│   │   ├── inventory_service_spec.rb
│   │   ├── loan_service_spec.rb
│   │   ├── notification_service_spec.rb
│   │   ├── return_service_spec.rb
│   │   ├── search_service_spec.rb
│   │   └── user_service_spec.rb
│   ├── support/                              # テスト共通設定
│   │   └── uuid_configuration_spec.rb
│   ├── rails_helper.rb
│   └── spec_helper.rb
├── test/                                     # Minitest標準テスト（主にRSpec使用）
│   ├── controllers/
│   ├── fixtures/
│   │   └── files/
│   ├── helpers/
│   ├── integration/
│   ├── mailers/
│   ├── models/
│   ├── system/
│   └── test_helper.rb
├── vendor/                                   # サードパーティライブラリ
│   └── javascript/
├── CLAUDE.md                                 # Claude Code設定・AI開発ガイドライン
├── Dockerfile
├── Gemfile                                   # Gem依存関係定義
├── Gemfile.lock
├── Rakefile
├── README.md
├── config.ru                                 # Rackアプリケーション起動設定
└── render.yaml                               # Renderデプロイ設定
```

---

## 主要ディレクトリ説明

| ディレクトリ | 役割 |
|---|---|
| `app/models/` | ActiveRecordモデル（User・Category・Equipment・Loan） |
| `app/controllers/` | HTTPリクエスト処理（一般ユーザー・管理者） |
| `app/services/` | ビジネスロジック（貸出・返却・検索・通知等） |
| `app/policies/` | Punditによるアクションレベルの認可制御 |
| `app/jobs/` | 延滞チェック等のバックグラウンド処理 |
| `app/mailers/` | 貸出確認・在庫不足・延滞アラートメール送信 |
| `config/` | ルーティング・DB・環境・スケジュール設定 |
| `db/migrate/` | データベーススキーマ変更履歴 |
| `spec/` | RSpecによる単体・統合・E2Eテスト |
| `docs/` | 設計書・ER図・API仕様等のドキュメント |
