class AddKindToStories < ActiveRecord::Migration[6.0]
  def change
    add_column :stories, :kind, :string
    add_column :stories, :kind_guid, :string
  end
end
