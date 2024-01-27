class Note < ApplicationRecord
  belongs_to :notebook
  has_many :notes_tags, dependent: :destroy
  has_many :tags, through: :notes_tags

  after_update :broadcast_update
  after_destroy :broadcast_destroy

  private

  def broadcast_update
    broadcast_replace_to(
      self,
      target: self,
      partial: 'notes/note',
      locals: { note: self, broadcasted: true }
    )
  end

  def broadcast_destroy
    broadcast_replace_to(
      self,
      target: self,
      html: 'sorry, I got destroyed'
    )
  end
end
