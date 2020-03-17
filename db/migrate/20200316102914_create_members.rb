class CreateMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :members do |t|
      t.string :guid
      t.string :name

      t.index :guid, unique: true
    end
  end
end
