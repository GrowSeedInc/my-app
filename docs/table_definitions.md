# テーブル定義書

## 概要

| テーブル名 | 論理名 | 説明 |
|---|---|---|
| categories | カテゴリ | 備品のカテゴリ分類 |
| equipments | 備品 | 管理対象の備品情報 |
| loans | 貸出 | 備品の貸出申請・履歴 |
| users | ユーザー | システム利用者（一般・管理者） |

---

## 1. categories（カテゴリ）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---|---|---|---|---|
| id | uuid | NOT NULL | gen_random_uuid() | 主キー（UUID） |
| name | string | NOT NULL | — | カテゴリ名 |
| created_at | datetime | NOT NULL | — | 作成日時 |
| updated_at | datetime | NOT NULL | — | 更新日時 |

### インデックス

| インデックス名 | カラム | UNIQUE |
|---|---|---|
| index_categories_on_name | name | ✓ |

### リレーション

| 種別 | 対象テーブル | 説明 |
|---|---|---|
| has_many | equipments | カテゴリは複数の備品を持つ |

---

## 2. equipments（備品）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---|---|---|---|---|
| id | uuid | NOT NULL | gen_random_uuid() | 主キー（UUID） |
| category_id | uuid | NULL | — | 外部キー（categories.id） |
| name | string | NOT NULL | — | 備品名 |
| management_number | string | NOT NULL | — | 管理番号（一意） |
| description | text | NULL | — | 備品の説明・備考 |
| status | string | NOT NULL | `available` | ステータス（後述） |
| total_count | integer | NOT NULL | 0 | 総数量 |
| available_count | integer | NOT NULL | 0 | 貸出可能数量 |
| low_stock_threshold | integer | NULL | 0 | 在庫不足アラート閾値 |
| discarded_at | datetime | NULL | — | 論理削除日時（NULLは有効） |
| created_at | datetime | NOT NULL | — | 作成日時 |
| updated_at | datetime | NOT NULL | — | 更新日時 |

### status 値一覧

| 値 | 意味 |
|---|---|
| `available` | 貸出可能 |
| `in_use` | 貸出中 |
| `repair` | 修理中 |
| `disposed` | 廃棄済み |

### インデックス

| インデックス名 | カラム | UNIQUE |
|---|---|---|
| index_equipments_on_category_id | category_id | — |
| index_equipments_on_management_number | management_number | ✓ |
| index_equipments_on_status_and_discarded_at | status, discarded_at | — |

### 外部キー制約

| カラム | 参照先 |
|---|---|
| category_id | categories.id |

### リレーション

| 種別 | 対象テーブル | 説明 |
|---|---|---|
| belongs_to | categories | 備品はカテゴリに属する（optional） |
| has_many | loans | 備品は複数の貸出を持つ |

### 備考

- `discarded_at` が NULL でないレコードは論理削除済み（Discard gem を使用）
- `available_count` は `total_count` から現在の貸出数を引いた値

---

## 3. loans（貸出）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---|---|---|---|---|
| id | uuid | NOT NULL | gen_random_uuid() | 主キー（UUID） |
| equipment_id | uuid | NOT NULL | — | 外部キー（equipments.id） |
| user_id | uuid | NOT NULL | — | 外部キー（users.id） |
| status | string | NOT NULL | `pending_approval` | 貸出ステータス（後述） |
| start_date | date | NOT NULL | — | 貸出開始日 |
| expected_return_date | date | NOT NULL | — | 返却予定日 |
| actual_return_date | date | NULL | — | 実際の返却日 |
| created_at | datetime | NOT NULL | — | 作成日時 |
| updated_at | datetime | NOT NULL | — | 更新日時 |

### status 値一覧

| 値 | 意味 |
|---|---|
| `pending_approval` | 承認待ち |
| `active` | 貸出中（承認済み） |
| `returned` | 返却済み |
| `overdue` | 延滞中 |

### インデックス

| インデックス名 | カラム | UNIQUE |
|---|---|---|
| index_loans_on_equipment_id | equipment_id | — |
| index_loans_on_equipment_id_and_status | equipment_id, status | — |
| index_loans_on_user_id | user_id | — |
| index_loans_on_user_id_and_status | user_id, status | — |
| index_loans_on_status_and_expected_return_date | status, expected_return_date | — |

### 外部キー制約

| カラム | 参照先 |
|---|---|
| equipment_id | equipments.id |
| user_id | users.id |

### リレーション

| 種別 | 対象テーブル | 説明 |
|---|---|---|
| belongs_to | equipments | 貸出は備品に属する |
| belongs_to | users | 貸出はユーザーに属する |

### 備考

- `expected_return_date` は `start_date` より後の日付でなければならない（バリデーション）
- 毎日00:30にバッチ処理が実行され、`active` かつ `expected_return_date` 超過のレコードが `overdue` に遷移する

---

## 4. users（ユーザー）

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---|---|---|---|---|
| id | uuid | NOT NULL | gen_random_uuid() | 主キー（UUID） |
| name | string | NULL | — | 氏名 |
| email | string | NOT NULL | `''` | メールアドレス（ログインID） |
| encrypted_password | string | NOT NULL | `''` | 暗号化パスワード（Devise管理） |
| role | integer | NOT NULL | 0 | 権限（後述） |
| reset_password_token | string | NULL | — | パスワードリセット用トークン |
| reset_password_sent_at | datetime | NULL | — | パスワードリセットメール送信日時 |
| remember_created_at | datetime | NULL | — | ログイン状態保持の開始日時 |
| created_at | datetime | NOT NULL | — | 作成日時 |
| updated_at | datetime | NOT NULL | — | 更新日時 |

### role 値一覧

| 値 | 意味 |
|---|---|
| `0` (`member`) | 一般ユーザー |
| `1` (`admin`) | 管理者 |

### インデックス

| インデックス名 | カラム | UNIQUE |
|---|---|---|
| index_users_on_email | email | ✓ |
| index_users_on_reset_password_token | reset_password_token | ✓ |
| index_users_on_role | role | — |

### リレーション

| 種別 | 対象テーブル | 説明 |
|---|---|---|
| has_many | loans | ユーザーは複数の貸出を持つ |

### 備考

- 認証は Devise gem が管理（`database_authenticatable`, `recoverable`, `rememberable`）
- パスワードは最小8文字
- `email` はシステム内で一意

---

## ER図（テキスト表現）

```
categories ──< equipments ──< loans >── users
```

- `categories` 1対多 `equipments`（カテゴリは任意、optional）
- `equipments` 1対多 `loans`
- `users` 1対多 `loans`
