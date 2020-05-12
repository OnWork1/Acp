class Members::AccountsController < Members::BaseController
  # GET /account
  def show
  end

  # GET /account/edit
  def edit
  end

  # PATCH /account
  def update
    current_member.audit_session = current_session

    if current_member.update(member_params)
      redirect_to members_account_path
    else
      render :edit
    end
  end

  private

  def member_params
    params
      .require(:member)
      .permit(
        :name,
        :address, :zip, :city,
        :emails, :phones)
  end
end
