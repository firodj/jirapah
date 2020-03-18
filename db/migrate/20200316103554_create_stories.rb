class CreateStories < ActiveRecord::Migration[6.0]
  def change
    create_table :stories do |t|
      t.string :guid
      t.string :key
      t.text :summary
      t.string :epic_link
      t.string :project_guid
      t.references :reporter, foreign_key: {to_table: :members}
      t.references :assignee, foreign_key: {to_table: :members}
      t.references :creator, foreign_key: {to_table: :members}
      t.references :pair_assignee, foreign_key: {to_table: :members}
      t.references :qa_tester, foreign_key: {to_table: :members}
      t.integer :story_point
      t.text :labels
      t.string :status
      t.string :status_guid
      t.string :resolution
      t.string :resolution_guid
      t.datetime :resolved_at
      t.datetime :updated_at
      t.datetime :created_at

      t.index :guid, unique: true
    end
  end
end
