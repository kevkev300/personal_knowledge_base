class Tag < ApplicationRecord
  has_many :notes_tags, dependent: :destroy
  has_many :notes, through: :notes_tags
end
