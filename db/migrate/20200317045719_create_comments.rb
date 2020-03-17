class CreateComments < ActiveRecord::Migration[6.0]
  def change
    create_table :comments do |t|
      t.string :guid
      t.references :story
      t.references :author, foreign_key: {to_table: :members}
      t.references :editor, foreign_key: {to_table: :members}

      t.datetime :created_at
      t.datetime :updated_at

      t.index :guid, unique: true
    end
  end
end
