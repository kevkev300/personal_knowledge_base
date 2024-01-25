class CreateNotebooks < ActiveRecord::Migration[7.0]
  def change
    create_table :notebooks do |t|
      t.string :name

      t.timestamps
    end
  end
end
