class Note < ApplicationRecord
  belongs_to :notebook, touch: true
  has_many :notes_tags, dependent: :destroy
  has_many :tags, through: :notes_tags

  broadcasts_refreshes
end
