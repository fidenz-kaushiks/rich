class ActiveStorageFolders < ActiveRecord::Migration[5.2]
  def change
    create_table :active_storage_folders do |t|     
      t.string :folder_name
      t.integer :parent
      t.timestamps
    end
  end
end
