class Notebook < ApplicationRecord
  has_many :notes, dependent: :destroy

  broadcasts_refreshes
end
