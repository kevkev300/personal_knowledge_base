class AddDateToNote < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :date, :date
  end
end
