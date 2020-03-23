class AddEpicToStory < ActiveRecord::Migration[6.0]
  def change
    add_column :stories, :epic_id, :integer
  end
end
