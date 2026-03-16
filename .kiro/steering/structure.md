# Project Structure

## Organization Philosophy

Rails 標準のレイヤードアーキテクチャをベースに、**Service Object** と **Pundit Policy** を追加。
ビジネスロジック・認可ロジックはコントローラから切り離し、テスト可能な単独クラスに分離する。

## Directory Patterns

### Models（`app/models/`）
**目的**: ドメインオブジェクト。バリデーション・アソシエーション・enum定義のみ。
**例**: `Equipment`（ソフトデリート対応）、`Loan`（ステータス enum）
- ステータスは `enum :status, { key: "value" }` の文字列値形式
- ソフトデリートは `include Discard::Model`、有効レコードは `.kept` スコープで取得

### Services（`app/services/`）
**目的**: ビジネスロジックの集約。トランザクション・外部連携・複雑な状態遷移を担当。
**例**: `LoanService#create`、`ReturnService#process`、`SearchService#search_equipments`
- 命名: `XxxService`（対象ドメイン + Service）
- 戻り値: `{ success: Boolean, record: T, error: Symbol, message: String }`
- DB操作はトランザクション内で行い、排他ロックが必要な場合は `with_lock` を使用

### Policies（`app/policies/`）
**目的**: Pundit による action 単位の認可定義。
**例**: `EquipmentPolicy#update?`、`LoanPolicy#approve?`
- 命名: `XxxPolicy`（モデル名 + Policy）
- `ApplicationPolicy` を継承。`user.admin?` でロール判定
- コントローラで `authorize @record` を呼び、違反時は `Pundit::NotAuthorizedError`

### Controllers（`app/controllers/`）
**目的**: リクエスト受付・パラメータ検証・Service/Policy の呼び出し・レスポンス生成。
**例**: `EquipmentsController`、`LoansController`、`Admin::DashboardsController`
- 管理者専用機能は `admin/` サブディレクトリに名前空間化（`namespace :admin`）
  - 例: `Admin::DashboardsController`、`Admin::CategoriesController`、`Admin::LoansController`、`Admin::UsersController`
- すべての認証は `ApplicationController` の `before_action :authenticate_user!` に集約

### Jobs（`app/jobs/`）
**目的**: 非同期・定期処理。`ApplicationJob` 継承。
**例**: `OverdueCheckJob`（毎日00:30 に延滞チェック）
- Sidekiq バックエンド、Whenever でスケジュール管理（`config/schedule.rb`）

### Mailers（`app/mailers/`）
**目的**: メール通知テンプレート。`NotificationService` 経由で呼び出す。
**例**: `LoanMailer#loan_confirmation`、`LoanMailer#low_stock_alert`

### Views（`app/views/`）
**目的**: ERB テンプレート。Tailwind CSS クラスで直接スタイリング。
**ディレクトリ**: コントローラ名に対応（`equipments/`、`loans/`、`admin/dashboards/`）
- Singular resource（`resource :mypage`）でも Rails はコントローラ・ビューを複数形で扱う

## Naming Conventions

- **ファイル名**: snake_case（Rails 規約）
- **クラス名**: PascalCase
- **Service メソッド**: 動詞 + 対象（`create`、`approve`、`search_equipments`）
- **Policy メソッド**: アクション名 + `?`（`update?`、`approve?`）

## Testing Structure（`spec/`）

```
spec/
  models/         # モデルのバリデーション・アソシエーション
  services/       # Service Object の入出力・エラーハンドリング
  policies/       # Pundit Policy の権限テスト
  jobs/           # ジョブの実行ロジック
  mailers/        # メール生成
  requests/       # コントローラのHTTP統合テスト
  integration/    # 複数レイヤーをまたぐフローテスト（貸出・返却フロー、検索・ダッシュボード等）
  factories/      # FactoryBot ファクトリ定義
```

## Code Organization Principles

- **Fat Model を避ける**: モデルはデータ定義に専念。ロジックは Service へ
- **Controller は薄く**: パラメータ取得・Service 呼び出し・flash/redirect に限定
- **認可は Policy で一元化**: コントローラ内での条件分岐で認可を行わない

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_
