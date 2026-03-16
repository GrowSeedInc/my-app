class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:users, :role)
      add_column :users, :role, :integer, null: false, default: 0
    end
    unless index_exists?(:users, :role)
      add_index :users, :role
    end
  end
end
