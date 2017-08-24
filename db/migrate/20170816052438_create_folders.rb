class CreateFolders < ActiveRecord::Migration
  def up
    create_table :folders do |t|
    	t.string :folder_name
      t.integer :parent_id, default: -1

      t.timestamps null: false
    end

    add_reference :rich_rich_files, :folder, index: true, foreign_key: true, default: -1 
  end
end
