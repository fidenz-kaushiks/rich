class AddTitleToRich < ActiveRecord::Migration
  def up
    add_column :rich_rich_files, :titles, :text
  end

  def down
    add_column :rich_rich_files, :titles, :text
  end
end
