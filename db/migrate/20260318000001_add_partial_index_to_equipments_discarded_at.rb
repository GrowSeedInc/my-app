class AddPartialIndexToEquipmentsDiscardedAt < ActiveRecord::Migration[8.1]
  def change
    # Equipment.kept (discarded_at IS NULL) は全クエリの基本スコープとして使われるため
    # NULL 専用の partial index を追加してフィルタリングを高速化する
    add_index :equipments, :discarded_at,
              name: "index_equipments_on_discarded_at_null",
              where: "discarded_at IS NULL"
  end
end
