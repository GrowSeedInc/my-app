class CreateLoans < ActiveRecord::Migration[7.0]
  def change
    create_table :loans, id: :uuid, default: "gen_random_uuid()" do |t|
      t.references :equipment, null: false, foreign_key: { to_table: :equipments }, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.date :start_date, null: false
      t.date :expected_return_date, null: false
      t.date :actual_return_date
      t.string :status, null: false, default: "pending_approval"

      t.timestamps
    end

    add_index :loans, [ :status, :expected_return_date ]
    add_index :loans, [ :user_id, :status ]
    add_index :loans, [ :equipment_id, :status ]
  end
end
