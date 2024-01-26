class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.references :notebook, null: false, foreign_key: true
      t.string :name
      t.string :note_type
      t.string :resource_url
      t.text :content

      t.timestamps
    end
  end
end
