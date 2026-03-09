# Research & Design Decisions

---
**Purpose**: Capture discovery findings, architectural investigations, and rationale that inform the technical design.

## Summary
- **Feature**: `equipment-management`
- **Discovery Scope**: New Feature（グリーンフィールド）
- **Key Findings**:
  - Ruby on Rails 7 + Hotwire（Turbo/Stimulus）により、追加のフロントエンドフレームワーク不要でリッチなUIを実現可能
  - Punditのポリシーベース認可が管理者/一般ユーザーの権限分離要件（Requirement 6）に最適
  - 貸出申請の在庫競合はPostgreSQLのSELECT FOR UPDATE（ActiveRecord `with_lock`）でアトミックに制御できる

---

## Research Log

### 技術スタック選定
- **Context**: ユーザー指定によりRuby on Rails + PostgreSQLを採用。ステアリング未定義のグリーンフィールドプロジェクト。
- **Sources Consulted**: Rails 7 Guides、Devise README、Pundit README、Sidekiq Wiki
- **Findings**:
  - Rails 7 + Hotwireにより、JavaScript最小構成でページ遷移なしのUI更新が可能
  - Deviseはセッション管理・パスワードハッシュ化（bcrypt）・CSRF保護のデファクトスタンダード
  - Punditはポリシークラスを各リソースに対応させてテストしやすい認可設計が可能
  - Sidekiq + Wheneverは延滞チェックのような定期バッチに実績豊富な組み合わせ
- **Implications**: 単一のRailsアプリで全要件を満たせる。追加フレームワーク不要。

### 在庫競合制御
- **Context**: Requirement 2.1〜2.2「貸出申請時の在庫確認」において複数ユーザーの同時申請による在庫超過が発生しうる
- **Sources Consulted**: Rails ActiveRecord Locking Guide、PostgreSQL SELECT FOR UPDATE
- **Findings**:
  - `ActiveRecord`の`with_lock`メソッドはSELECT FOR UPDATEを発行し、同一レコードへの同時更新を直列化する
  - Optimistic Lockingは更新時の衝突検知に適するが、在庫チェック〜デクリメントの間隔でもレース条件が発生しうる
  - Pessimistic LockingはSELECT FOR UPDATEで確実にアトミック性を保証できる
- **Implications**: LoanServiceの`create`メソッド内でEquipmentを`with_lock`してトランザクション内で在庫確認・更新を実施

### 延滞チェックバッチ設計
- **Context**: Requirement 3.3「返却予定日を過ぎた貸出レコードを自動的にoverdueステータスへ変更」
- **Sources Consulted**: Sidekiq Wiki、Whenever README
- **Findings**:
  - WheneverはcrontabをシンプルなRuby DSLで記述できる
  - ActiveJobインターフェース経由でSidekiqジョブを実行することで、テスト時はインラインアダプタに切替可能
  - 日次実行（00:30）で十分。対象クエリは`WHERE status = 'active' AND expected_return_date < CURRENT_DATE`
- **Implications**: `OverdueCheckJob`は冪等性を自然に確保（既にoverdueのレコードは対象外）

---

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| Rails Monolith + Hotwire | 単一Railsアプリ、Turbo/Stimulusでリッチ化 | シンプル・高速開発・Rails慣習に準拠 | スケール時の分割が必要 | 社内ツールに最適。今回採用。 |
| Rails API + React SPA | APIサーバーとReactフロントを分離 | フロント柔軟性高い | 開発コスト増・CORS管理必要 | 不採用 |
| マイクロサービス | 機能ごとにサービス分割 | 独立スケール可能 | 過剰設計・運用コスト高 | 今回の規模に不適。不採用。 |

---

## Design Decisions

### Decision: Railsモノリス + Service層の採用
- **Context**: 社内業務アプリとして開発速度・保守性を優先
- **Alternatives Considered**:
  1. Rails API + React SPA
  2. Rails Monolith + Hotwire（採用）
- **Selected Approach**: Layered Monolith（MVC + Service Layer）
- **Rationale**: 社内ツールはまず動くものを素早く届けることが重要。HotwireによりJSフレームワークなしでリッチなインタラクションを実現できる。Service層でビジネスロジックをコントローラーから分離し保守性を確保。
- **Trade-offs**: 将来モバイルアプリ連携が必要になった場合はAPIエンドポイントを追加公開する必要がある
- **Follow-up**: スケール要件が増えた場合にAPI分離の検討

### Decision: Punditによるポリシーベース認可
- **Context**: 管理者と一般ユーザーで操作可能な機能が明確に異なる（Requirement 6.3）
- **Alternatives Considered**:
  1. Pundit（ポリシークラス）— 採用
  2. CanCanCan（Abilityクラス）
  3. Deviseのrole属性のみで制御
- **Selected Approach**: Pundit
- **Rationale**: リソース別にポリシーファイルが分かれるため見通しが良く、単体テストが書きやすい。`verify_authorized`でポリシー適用漏れを検出できる。
- **Trade-offs**: CanCanCanに比べてボイラープレートが多いが、コードが明示的で追跡しやすい

### Decision: 悲観的ロックによる在庫競合制御
- **Context**: 同時貸出申請による在庫超過防止（Requirement 2.1, 2.2）
- **Alternatives Considered**:
  1. 楽観的ロック（lock_version）
  2. 悲観的ロック（SELECT FOR UPDATE）— 採用
- **Selected Approach**: ActiveRecord `with_lock`（SELECT FOR UPDATE）
- **Rationale**: 貸出申請は頻度が低くロック競合のリスクは小さい。実装がシンプルで在庫チェック〜更新のアトミック性を確実に保証できる。
- **Trade-offs**: 高頻度アクセス時はスループット低下の可能性があるが、社内利用では問題なし

### Decision: Sidekiq + Wheneverによる延滞チェック
- **Context**: Requirement 3.3の自動延滞ステータス更新
- **Alternatives Considered**:
  1. Sidekiq + Whenever — 採用
  2. Rails 8 Solid Queue
  3. 外部スケジューラー（Heroku Schedulerなど）
- **Selected Approach**: Sidekiq + Whenever
- **Rationale**: Sidekiqは実績豊富でWebUIによる監視が充実。Wheneverでcrontabを宣言的管理。将来の非同期処理拡張にも対応可能。
- **Trade-offs**: Redis依存が追加されるが許容範囲

---

## Risks & Mitigations
- 延滞チェックジョブの実行失敗 — Sidekiqのリトライ機構 + Sidekiq Webで監視
- 在庫競合による二重貸出 — トランザクション内悲観的ロックで防止
- メール配信失敗 — `deliver_later`のリトライ機構 + エラーログ記録

---

## References
- [Rails 7 Guides](https://guides.rubyonrails.org/) — Rails 7アーキテクチャ・ActiveRecord・Hotwire
- [Devise README](https://github.com/heartcombo/devise) — 認証gem
- [Pundit README](https://github.com/varvet/pundit) — ポリシーベース認可
- [Sidekiq Wiki](https://github.com/sidekiq/sidekiq/wiki) — バックグラウンドジョブ
- [Whenever README](https://github.com/javan/whenever) — Cronスケジューラー
- [ActiveRecord Locking Guide](https://guides.rubyonrails.org/active_record_querying.html#locking-records-for-update) — 悲観的/楽観的ロック
