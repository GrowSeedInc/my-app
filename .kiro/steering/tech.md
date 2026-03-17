# Technology Stack

## Architecture

Rails モノリス（MVC + Service Object + Policy）。Hotwire（Turbo/Stimulus）でページ遷移を SPA ライクに高速化。
バックエンドに Rails、フロントエンドに Tailwind CSS + Hotwire を使い、JavaScript フレームワークは導入しない。

## Core Technologies

- **Language**: Ruby（Bundler でバージョン管理）
- **Framework**: Rails 8.1.2
- **Database**: PostgreSQL（pgcrypto 拡張で UUID 主キー）
- **Asset Pipeline**: Propshaft + importmap-rails
- **CSS**: Tailwind CSS（`bin/rails tailwindcss:build` でビルド）
- **Frontend**: Hotwire（Turbo Rails + Stimulus Rails）

## Key Libraries

| Gem | 役割 |
|-----|------|
| devise | 認証（User モデル自動生成、ルート `devise_for :users`） |
| pundit | 認可（Policy クラスで action 単位に権限定義） |
| discard | ソフトデリート（`discarded_at` カラム、`kept` スコープ） |
| sidekiq | バックグラウンドジョブ（Gemfile に含む。キューバックエンドは solid_queue を使用） |
| whenever | Cron スケジューリング（`config/schedule.rb`） |
| solid_queue / solid_cache / solid_cable | DB バックドのキュー・キャッシュ・WebSocket（`config.active_job.queue_adapter = :solid_queue`） |
| rspec-rails | テストフレームワーク |
| factory_bot_rails | テストデータファクトリ |
| capybara + selenium-webdriver | システムテスト（E2E） |

## Development Standards

### Authentication & Authorization
- 全アクションに `before_action :authenticate_user!`（ApplicationController）
- 認可は Pundit Policy で行い、コントローラで `authorize @record` を呼ぶ
- ロールは `User#admin?` / `User#member?` で判定（enum）

### Service Object パターン
- ビジネスロジックは `app/services/XxxService` に集約
- 戻り値は `{ success: Boolean, [record: T], [error: Symbol], [message: String] }` ハッシュ
- トランザクション・排他ロック（`with_lock`）は Service 内で処理

### コード品質
- RuboCop（rubocop-rails-omakase）+ Brakeman（セキュリティ静的解析）+ bundler-audit（Gem 脆弱性チェック）
- RSpec によるユニット・統合・E2E テスト

## Development Environment

### 注意事項
- Ruby / Rails はローカル未インストール。すべてのコマンドはコンテナ内で実行。
- アセット変更後は `bin/rails tailwindcss:build` または `bin/rails assets:precompile` を実行。

### Common Commands（コンテナ内）
```bash
# Dev server
bin/rails server

# Tailwind rebuild
bin/rails tailwindcss:build

# Test
bundle exec rspec

# Lint
bundle exec rubocop
bundle exec brakeman

# Cron schedule update
bundle exec whenever --update-crontab
```

## Key Technical Decisions

- **UUID 主キー**: pgcrypto で `gen_random_uuid()` を使用。セキュリティと分散対応。
- **Soft Delete**: Discard gem。物理削除せず `discarded_at` で論理削除し、`Equipment.kept` で有効レコードを取得。
- **排他ロック**: 貸出申請時に `equipment.with_lock` でレコードロックし、在庫の二重減算を防止。
- **`equipment` 不規則複数形**: Railsのinflectorが `equipment` を単数・複数同形扱いするため `config/initializers/inflections.rb` で `inflect.irregular "equipment", "equipments"` を設定し、モデルに `self.table_name = "equipments"` を明示。

---
_Document standards and patterns, not every dependency_
