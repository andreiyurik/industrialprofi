class AccountController < ApplicationController
  def show
  end

  def update
    if Current.user.update(name_params)
      redirect_to account_path, notice: t("account.name_updated")
    else
      flash.now[:alert] = Current.user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private
    def name_params
      params.expect(user: [ :name ])
    end
end
