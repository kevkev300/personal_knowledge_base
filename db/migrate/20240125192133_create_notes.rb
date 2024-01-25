class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.references :notebook, null: false, foreign_key: true
      t.text :content
      t.string :resource_url

      t.timestamps
    end
  end
end
