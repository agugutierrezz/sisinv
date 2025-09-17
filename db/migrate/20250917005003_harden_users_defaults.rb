# Sirve para que el rol del usuario sea 0:user por default
class HardenUsersDefaults < ActiveRecord::Migration[8.0]
  def up
    change_column_default :users, :role, 0
    execute "UPDATE users SET role = 0 WHERE role IS NULL"
    change_column_null :users, :role, false
    add_index :users, :api_token, unique: true unless index_exists?(:users, :api_token)
  end

  def down
    remove_index :users, :api_token if index_exists?(:users, :api_token)
    change_column_null :users, :role, true
    change_column_default :users, :role, nil
  end
end
