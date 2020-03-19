class CreateChangeLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :change_logs do |t|
      t.string :guid
      t.references :story
      t.references :author, foreign_key: {to_table: :members}
      t.text :description
      t.datetime :changed_at

      t.index :guid, unique: true
    end
  end
end
