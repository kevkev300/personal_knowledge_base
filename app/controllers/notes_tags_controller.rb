class NotesTagsController < ApplicationController
  def create
    note_tag = NotesTag.new(notes_tag_params)
    note_tag.save

    redirect_back(fallback_location: root_path)
  end

  def destroy
    note_tag = NotesTag.find(params[:id])
    note_tag.destroy

    redirect_back(fallback_location: root_path)
  end

  private

  def notes_tag_params
    params.require(:notes_tag).permit(:note_id, :tag_id)
  end
end
