class NotebooksController < ApplicationController
  before_action :set_notebook, only: %i[ show edit update destroy ]

  # GET /notebooks
  def index
    @notebooks = Notebook.all
  end

  # GET /notebooks/1
  def show
  end

  # GET /notebooks/new
  def new
    @notebook = Notebook.new
  end

  # GET /notebooks/1/edit
  def edit
  end

  # POST /notebooks
  def create
    @notebook = Notebook.new(notebook_params)

    if @notebook.save
      redirect_to @notebook, notice: "Notebook was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /notebooks/1
  def update
    if @notebook.update(notebook_params)
      redirect_to @notebook, notice: "Notebook was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /notebooks/1
  def destroy
    @notebook.destroy
    redirect_to notebooks_url, notice: "Notebook was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notebook
      @notebook = Notebook.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def notebook_params
      params.require(:notebook).permit(:name)
    end
end
