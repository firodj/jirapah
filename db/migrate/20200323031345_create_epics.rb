class CreateEpics < ActiveRecord::Migration[6.0]
  def change
    create_table :epics do |t|
      t.string :title
      t.string :key
      t.references :story, null: false, foreign_key: true
    end
  end
end
