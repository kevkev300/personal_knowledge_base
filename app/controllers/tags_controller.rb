class TagsController < ApplicationController
  before_action :set_tag, only: %i[show edit update destroy]

  # GET /tags
  def index
    @tags = Tag.all.order(:name)
  end

  # GET /tags/1
  def show; end

  # GET /tags/new
  def new
    @tag = Tag.new
  end

  # GET /tags/1/edit
  def edit; end

  # POST /tags
  def create
    @tag = Tag.new(tag_params)

    return if @tag.save

    render :new, status: :unprocessable_entity
  end

  # PATCH/PUT /tags/1
  def update
    if @tag.update(tag_params)
      redirect_to @tag, notice: 'Tag was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tags/1
  def destroy
    @tag.destroy
    redirect_to tags_url, notice: 'Tag was successfully destroyed.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def tag_params
    params.require(:tag).permit(:name)
  end
end
