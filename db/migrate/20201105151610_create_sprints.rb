class CreateSprints < ActiveRecord::Migration[6.0]
  def change
    create_table :sprints do |t|
      t.string :guid
      t.string :name

      t.index :guid, unique: true
    end

    create_table :sprints_stories do |t|
      t.references :sprint
      t.references :story
    end
  end
end
