class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.string :guid
      t.references :story
      t.references :author, foreign_key: {to_table: :members}
      t.references :editor, foreign_key: {to_table: :members}

      t.datetime :posted_at
      t.datetime :changed_at

      t.index :guid, unique: true
    end
  end
end
