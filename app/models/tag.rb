class Tag < ApplicationRecord
  has_many :notes_tags, dependent: :destroy
  has_many :notes, through: :notes_tags

  scope :not_with_note, ->(note) { where.not(id: note.tags) }
end
