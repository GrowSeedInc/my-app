# Implementation Plan

## hamburger-sidebar

---

- [ ] 1. (P) Stimulus サイドバーコントローラーの実装
- [ ] 1.1 開閉トグル・localStorage 永続化・aria-expanded 管理を実装する
  - `sidebar_controller.js` を `app/javascript/controllers/` に新規作成する（`eagerLoadControllersFrom` により自動登録される）
  - `toggle()`・`open()`・`close()` アクションを実装し、サイドバーパネル・メインエリア・ハンバーガーボタンの各ターゲットに開閉クラスを付与する
  - `localStorage["sidebarOpen"]` に `"true"` / `"false"` を保存・読み込みする `saveState()` / `restoreState()` を実装する
  - `connect()` 時に `restoreState()` で保存値を取得し、なければブレークポイント判定（`window.matchMedia("(min-width: 1024px)")`）でデフォルト状態を決定して適用する
  - `open()` / `close()` のたびに `hamburgerTarget.ariaExpanded` を `"true"` / `"false"` に更新する
  - _Requirements: 2.2, 2.6, 4.1_

- [ ] 1.2 click-outside 検出とスクリムクリック処理を実装する
  - コントローラーラッパー要素に `data-action="click@window->sidebar#handleWindowClick"` を設定することを前提に `handleWindowClick(event)` を実装する
  - `handleWindowClick` 内で `panelTarget.contains(event.target)` を確認し、サイドバーパネル外のクリックかつサイドバーが開いている場合のみ `close()` を呼ぶ
  - `close()` アクションをモバイルスクリム用にも使用できるようにする（スクリム `data-action="click->sidebar#close"` と共通化）
  - _Requirements: 2.7, 3.4_

- [ ] 1.3 モバイル・デスクトップのデフォルト状態を初期化時に正しく設定する
  - `connect()` で `localStorage` に値がない初回アクセス時、`window.matchMedia("(min-width: 1024px)").matches` が `true` なら open、`false` なら closed をデフォルト状態として適用する
  - `applyState(isOpen)` を冪等に実装し、Turbo Frame 再接続時の二重初期化が起きないようにする
  - _Requirements: 3.1, 3.3_

---

- [ ] 2. (P) レイアウト HTML の再構成
- [ ] 2.1 上部ヘッダーを廃止し、サイドバー + メインコンテンツの 2 カラム構造を構築する
  - `application.html.erb` から `<header>` ブロック全体を削除する
  - `user_signed_in?` ガードを維持しつつ、`data-controller="sidebar"` と `data-action="click@window->sidebar#handleWindowClick"` を持つラッパー `<div>` でサイドバーパネル・スクリム・メインエリアを包む
  - ハンバーガーボタン（`data-sidebar-target="hamburger"`・`data-action="click->sidebar#toggle"`・`aria-expanded="true"`・`aria-label="メニューを開閉する"`）をメインエリアの最上部に配置する
  - メインコンテンツエリアは `data-sidebar-target="main"` を付与し、サイドバー開閉に応じて左マージンが変化するようにする
  - 未ログイン時はサイドバー全体を表示せず、従来通り `<main>` のみ表示する
  - _Requirements: 1.1, 2.1, 2.3, 4.4_

- [ ] 2.2 ナビゲーション・ユーザー情報・ログアウトをサイドバーパネルに移設する
  - `<aside data-sidebar-target="panel">` を作成し、ロゴリンク・ナビゲーションリンク・ユーザー情報・ログアウトボタンを配置する
  - 既存の `controller_name` 比較によるアクティブハイライトロジックをサイドバー内のリンクに引き継ぐ
  - `current_user.admin?` による管理者専用リンク（ダッシュボード・ユーザー管理・カテゴリ管理）の条件分岐を維持する
  - `button_to` によるログアウトボタン（`method: :delete`）をサイドバー下部に配置する
  - フラッシュメッセージ（`notice` / `alert`）はメインコンテンツエリア内・`<main>` の直前に配置し、現行の表示ロジックを保持する
  - _Requirements: 1.2, 1.3, 1.4, 1.5, 4.3_

- [ ] 2.3 レスポンシブ対応・Tailwind CSS スタイリングとアニメーションを設定する
  - サイドバーパネルにモバイルオーバーレイ用の `fixed inset-y-0 left-0 z-30` クラスとデスクトップ用の `lg:relative` を組み合わせたレスポンシブクラスを設定する
  - 開閉アニメーションとして `transition-transform duration-300` を付与し、open 時は `translate-x-0`、closed 時は `-translate-x-full` で切り替える（SidebarController がクラスを付け替える）
  - サイドバーが開いている時のラベルテキスト表示・閉じている時の折りたたみ（または幅縮小）を CSS クラスで制御する
  - モバイルスクリム（`data-sidebar-target="scrim"`・`data-action="click->sidebar#close"`）を半透明の固定オーバーレイとして設定し、サイドバー開時のみ表示する
  - 使用する全 Tailwind クラスは文字列結合せず完全形で記述し、本番ビルドの purge による除外を防ぐ
  - _Requirements: 2.4, 2.5, 3.2, 3.4, 4.2_

---

- [ ] 3. テストと動作確認
- [ ] 3.1 サイドバーコントローラーの開閉ロジックをシステムテストで検証する
  - ハンバーガーボタンをクリックするとサイドバーが閉じ、再度クリックすると開くことを確認する
  - サイドバーが開いている状態でサイドバー外をクリックするとサイドバーが閉じることを確認する
  - ページ遷移後（別ページへ移動後）もサイドバーの開閉状態が保持されることを確認する
  - ハンバーガーボタンの `aria-expanded` が開閉状態と連動して `"true"` / `"false"` に切り替わることを確認する
  - _Requirements: 2.2, 2.6, 2.7, 3.1, 3.3, 4.1_

- [ ]* 3.2 Request spec でロール別 HTML 出力とアクセス制御を検証する
  - ログイン済み一般ユーザーのレスポンスに `data-controller="sidebar"` が含まれることを確認する
  - ログイン済み管理者のレスポンスに管理者専用リンク（ダッシュボード・ユーザー管理・カテゴリ管理）が含まれることを確認する
  - ログイン済み一般ユーザーのレスポンスに管理者専用リンクが含まれないことを確認する
  - 未ログイン状態でのレスポンスにサイドバー HTML が含まれないことを確認する
  - _Requirements: 1.3, 1.4, 4.4_

- [ ] 3.3 モバイル画面でのレスポンシブ動作と開閉アニメーションを確認する
  - モバイルサイズ（Capybara window resize）でページを開いた時にサイドバーがデフォルトで非表示であることを確認する
  - モバイルサイズでハンバーガーボタンをクリックするとサイドバーがオーバーレイとして表示されることを確認する
  - モバイルサイズでスクリムをクリックするとサイドバーが閉じることを確認する
  - 開閉時に CSS トランジションクラスが付与されていることを確認する
  - _Requirements: 3.1, 3.2, 3.4, 4.2_
