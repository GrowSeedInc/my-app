class CreateEquipments < ActiveRecord::Migration[7.0]
  def change
    create_table :equipments, id: :uuid, default: "gen_random_uuid()" do |t|
      t.string :name, null: false
      t.references :category, null: true, foreign_key: true, type: :uuid
      t.string :management_number, null: false
      t.text :description
      t.integer :total_count, null: false, default: 0
      t.integer :available_count, null: false, default: 0
      t.string :status, null: false, default: "available"
      t.integer :low_stock_threshold, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :equipments, :management_number, unique: true
    add_index :equipments, [ :status, :discarded_at ]
  end
end
