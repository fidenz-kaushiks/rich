class CreateRichRichImages < ActiveRecord::Migration[6.0]
  def change
    create_table :rich_rich_files do |t|

      t.string :rich_file_file_name
      t.string :rich_file_content_type
      t.integer :rich_file_file_size
      t.datetime :rich_file_updated_at
      t.text :uri_cache
      t.string :simplified_type, :default => "file"
      t.integer :parent_id, :default => 0

      t.timestamps
    end
  end
end
