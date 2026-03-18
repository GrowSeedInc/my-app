# 設計書: カテゴリCRUD機能

> **⚠️ このスペックは category-hierarchy スペックにより置き換えられました。**
>
> 本設計書に記載のフラットカテゴリ構造（単一の `Admin::CategoriesController`）は実装されていません。
> カテゴリ管理機能は `category-hierarchy` スペックの実装により、3階層構造（大分類/中分類/小分類）として実現されています。
> 最新の設計・実装については `.kiro/specs/category-hierarchy/design.md` を参照してください。

---

## 実装状況（参考）

category-hierarchy スペックにより以下のように実装されています。

| 設計書の記述（廃止） | 実際の実装 |
|---|---|
| `Admin::CategoriesController`（`resources :categories`） | `Admin::CategoryMajorsController` / `Admin::CategoryMediumsController` / `Admin::CategoryMinorsController` の3コントローラー |
| フラットカテゴリ（`name` 1カラム） | 3階層構造（大分類 / 中分類 / 小分類） |
| ナビリンク: `admin_categories_path` | `admin_category_majors_path` |
| `CategoryPolicy`（CRUD のみ） | `CategoryPolicy` に `by_major?` / `by_medium?` も追加済み |
| `SearchService#search_categories`（フラット検索） | 実装済みだが、UI は `Admin::CategoryMajorsController#index` の直接クエリに委譲 |

---

## 以下は廃止された元の設計書内容（参考記録）

<details>
<summary>元の設計書（クリックで展開）</summary>

### 元 Overview

本機能は、備品管理システムの管理者が備品カテゴリをブラウザから直接管理（一覧・作成・編集・削除）できるようにする。現状、`categories` テーブルはデータベースに存在するが、UI からの管理手段がない。

**Purpose**: 管理者がカテゴリのライフサイクルを完全に管理できる管理画面を提供する。
**Users**: 管理者（`admin` ロール）が備品分類の整理・追加・名称変更・廃止を行う。
**Impact**: 既存の `categories` テーブル・`Category` モデルに対して新たな管理 UI を追加する。データモデルの変更なし。

### 元 Goals

- 管理者がカテゴリの CRUD 操作をブラウザで完結できること
- 備品一覧と同じ UX パターン（検索・ドロップダウンソート）を提供すること
- 備品が紐づくカテゴリを誤って削除しないよう保護すること
- 既存の `Admin` 名前空間・Service・Policy パターンを踏襲し、実装一貫性を維持すること

### 元 Non-Goals

- 一般ユーザーへのカテゴリ管理権限付与
- カテゴリの階層化・ネスト構造（→ category-hierarchy スペックで実現）
- カテゴリの並び順（表示順）の手動並べ替え
- バルクインポート / エクスポート（→ csv-io スペックで実現）

</details>
