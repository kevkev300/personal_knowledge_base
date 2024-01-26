class Note < ApplicationRecord
  belongs_to :notebook
  has_many :notes_tags, dependent: :destroy
  has_many :tags, through: :notes_tags
end
