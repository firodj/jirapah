class AddParentToStory < ActiveRecord::Migration[6.0]
  def change
    add_reference :stories, :parent, foreign_key: {to_table: :stories}
    add_column :stories, :parent_key, :string
    add_column :stories, :parent_guid, :string
  end
end
