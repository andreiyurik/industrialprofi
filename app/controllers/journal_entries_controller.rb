class JournalEntriesController < ApplicationController
  rate_limit to: 20, within: 1.hour, only: %i[ create update ],
             with: -> { redirect_to journal_entries_path, alert: t("auth.rate_limited") }

  before_action :set_entry, only: %i[ edit update destroy ]

  def index
    @entries = Current.user.journal_entries.ordered.includes(:lesson, :rich_text_body, photos_attachments: :blob)
  end

  def new
    @entry = Current.user.journal_entries.new(lesson_id: params[:lesson_id])
  end

  def create
    @entry = Current.user.journal_entries.new(entry_params)

    if @entry.save
      redirect_to journal_entries_path, notice: t(".created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entry.update(entry_params)
      redirect_to journal_entries_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to journal_entries_path, notice: t(".deleted")
  end

  private
    def set_entry
      @entry = Current.user.journal_entries.find(params[:id])
    end

    def entry_params
      params.expect(journal_entry: [ :title, :body, :lesson_id, { photos: [] } ])
    end
end
