# Research & Design Decisions

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

---

## Summary

- **Feature**: `hamburger-sidebar`
- **Discovery Scope**: Extension（既存レイアウト変更）
- **Key Findings**:
  - Stimulus は `eagerLoadControllersFrom` で `app/javascript/controllers/*_controller.js` を自動登録。`sidebar_controller.js` を追加するだけで動作する。
  - Turbo Drive はページ遷移時に `<body>` を全置換するため、`data-` 属性はリセットされる。開閉状態の永続化には `localStorage` が必要。
  - importmap-rails 環境のため npm パッケージ追加不可。Stimulus・Tailwind CSS は既に利用可能で外部依存の追加は不要。

---

## Research Log

### Stimulus コントローラーの自動登録

- **Context**: 新しい Stimulus コントローラーをどう登録するか確認
- **Sources Consulted**: `app/javascript/controllers/index.js`
- **Findings**:
  - `eagerLoadControllersFrom("controllers", application)` により `app/javascript/controllers/*_controller.js` が自動検出・登録される
  - `sidebar_controller.js` というファイル名で配置するだけで `data-controller="sidebar"` として利用可能
- **Implications**: 手動 import / register 不要。ファイル配置のみで完結する。

### Turbo Drive とサイドバー状態の永続化

- **Context**: ページ遷移後もサイドバーの開閉状態を維持する（要件 2.6）
- **Sources Consulted**: Turbo Drive の動作仕様（body 差し替え）
- **Findings**:
  - Turbo Drive は `<body>` を全置換するため、body/要素の `data-` 属性はページ遷移のたびにリセットされる
  - `localStorage`・`sessionStorage` はページ遷移後も保持される
  - `localStorage` はタブ間でも共有されるが、サイドバー設定としては許容範囲
- **Implications**: `localStorage` に `"sidebarOpen"` キーで `"true"/"false"` を保存。Stimulus の `connect()` 時に復元し初期状態を適用する。

### click-outside 検出の実装方式

- **Context**: サイドバーが開いている時にサイドバー外クリックで閉じる（要件 2.7）
- **Sources Consulted**: Stimulus Action Descriptors ドキュメント
- **Findings**:
  - Stimulus は `data-action="click@window->sidebar#handleWindowClick"` で window レベルのクリックをキャプチャできる
  - `panelTarget.contains(event.target)` でクリック位置がサイドバー内か外かを判定可能
  - ハンバーガーボタン自体のクリックは `toggle()` → close に切り替わるため二重処理にならない
- **Implications**: `handleWindowClick` はデスクトップ・モバイル共通で動作。モバイルの scrim は視覚的補助として追加する。

---

## Architecture Pattern Evaluation

| Option | 説明 | 強み | リスク/制限 | 採否 |
|--------|------|------|-------------|------|
| localStorage | サイドバー状態を localStorage に保存 | Turbo 遷移後も保持、シンプル | タブ間同期（許容） | **採用** |
| sessionStorage | セッション中のみ保持 | タブ独立 | localStorage と大差なし | 非採用 |
| body data 属性 | body の data 属性で状態管理 | シンプル | Turbo Drive の body 差し替えでリセット | 非採用 |
| window click listener | `click@window` で外部クリック検出 | Stimulus 標準 API | バブリング制御が必要 | **採用** |
| 全画面透明 overlay | 透明 div で外部クリック検出 | 確実 | DOM 複雑化、アクセシビリティ懸念 | 非採用 |

---

## Design Decisions

### Decision: 状態永続化に localStorage を採用

- **Context**: Turbo Drive のページ遷移後もサイドバー開閉状態を保持する（要件 2.6）
- **Alternatives Considered**:
  1. `localStorage` — ブラウザ永続、Turbo 遷移を生き残る
  2. `sessionStorage` — セッション中保持、Turbo 遷移を生き残る
  3. `body` data 属性 — Turbo Drive による body 差し替えで失われる
- **Selected Approach**: `localStorage` の `"sidebarOpen"` キーに `"true"` / `"false"` を保存
- **Rationale**: Turbo Drive の body 差し替えを生き残り、ユーザーの操作を保持できる最もシンプルな手段
- **Trade-offs**: タブ間でサイドバー状態が同期される（ユーザー設定として問題なし）
- **Follow-up**: `connect()` 時に値が存在しない場合はブレークポイント判定でデフォルト値を設定する

### Decision: click-outside 検出に window click listener を採用

- **Context**: サイドバーが開いているときにサイドバー外クリックで閉じる（要件 2.7）
- **Alternatives Considered**:
  1. `click@window` action — Stimulus 標準 API、`contains()` で判定
  2. 全画面透明 overlay — 視覚的干渉の懸念
- **Selected Approach**: `data-action="click@window->sidebar#handleWindowClick"` + `panelTarget.contains(event.target)` による判定
- **Rationale**: Stimulus の標準的なパターンで実装がシンプル。モバイルの scrim と補完的に動作する。
- **Trade-offs**: ハンバーガーボタンのクリックが `toggle()` と `handleWindowClick` の両方に伝播するが、`toggle()` が先に実行されて状態が変わるため問題なし
- **Follow-up**: Turbo Frame 内でのイベント伝播動作を確認する

### Decision: デフォルト状態をブレークポイントで分岐

- **Context**: デスクトップはデフォルト開、モバイルはデフォルト閉（要件 3.1, 3.3）
- **Alternatives Considered**:
  1. CSS のみで制御 — JS 前にデフォルト状態を適用（FOUC 回避）
  2. Stimulus のみで制御 — JS 実行後にクラスを付与
  3. ハイブリッド — CSS でデフォルト、localStorage に値があれば JS で上書き
- **Selected Approach**: ハイブリッド。CSS クラスでデフォルト初期状態を定義し、Stimulus `connect()` で localStorage の値があれば上書き適用
- **Rationale**: FOUC を最小化しつつ、localStorage による状態復元も実現できる
- **Trade-offs**: CSS とクラス操作の二重管理が発生するが、Tailwind の transition クラスで統一できる
- **Follow-up**: モバイル判定は `window.matchMedia("(max-width: 1023px)")` で行う

---

## Risks & Mitigations

- **FOUC（Flash of Unstyled Content）**: ページロード時に localStorage 読み込み前にデフォルト状態が表示される可能性 → CSS デフォルトをデスクトップ open / モバイル closed に設定し、JS は差分のみ上書き
- **Tailwind CSS パージ**: 動的に追加するクラス名が本番ビルドで除外される可能性 → クラス名は文字列結合せず完全形で記述、または `safelist` に追加
- **Turbo Frame との干渉**: Turbo Frame 内ナビゲーションで Stimulus コントローラーが再 `connect()` する可能性 → `connect()` を冪等に実装し、2 回実行されても問題ない設計とする

---

## References

- [Stimulus Handbook - Action Descriptors](https://stimulus.hotwired.dev/reference/actions) — `click@window` パターンの根拠
- [Turbo Drive - Navigating](https://turbo.hotwired.dev/handbook/drive) — body 差し替え動作の確認
