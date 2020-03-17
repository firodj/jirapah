class CreateStories < ActiveRecord::Migration[6.0]
  def change
    create_table :stories do |t|
      t.string :guid
      t.string :key
      t.text :summary
      t.string :epic_link
      t.references :reporter, foreign_key: {to_table: :members}
      t.references :assignee, foreign_key: {to_table: :members}
      t.references :creator, foreign_key: {to_table: :members}
      t.references :pair_assignee, foreign_key: {to_table: :members}
      t.references :qa_tester, foreign_key: {to_table: :members}
      t.integer :story_point
      t.datetime :updated_at
      t.datetime :created_at

      t.index :guid, unique: true
    end
  end
end
