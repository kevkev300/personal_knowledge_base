class Notebook < ApplicationRecord
  has_many :notes, dependent: :destroy
end
