# frozen_string_literal: true

class PasswordsController < ApplicationController
  skip_before_action :authorized, only: %i[new create edit editReset updateReset]
  skip_before_action :AdminAuthorized, except: []

  def edit
    run Password::Operation::UpdatePassword::Present, user_id: current_user.id do |result|
      render cell(Password::Cell::Edit, @form, user: result[:model])
    end
  end

  def update
    # run Password::Operation::UpdatePassword, user_id: current_user.id do |_|
    #   return redirect_to root_path, notice: 'Your password has been changed.'
    # end
    # render cell(Password::Cell::Edit, @form)

    if current_user.authenticate(password_params[:old_password])
      if current_user.update(password_params)
        redirect_to root_path, notice: 'Your password has been changed.'
      else
        redirect_to password_path, notice: 'Something went wrong.'
      end
    else
      redirect_to password_path, notice: 'Your old password is wrong!'
    end
  end

  def new
    render cell(Password::Cell::New, @form)
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user.present?
      PasswordMailer.with(user: @user).reset.deliver_now
      redirect_to root_path, notice: 'We have sent a link to reset a password.'
    else
      redirect_to password_reset_path, notice: 'No account with this email exists.'
    end
  end

  def editReset
    @user = User.find_signed!(params[:token], purpose: 'password_reset')
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, notice: 'Your token has expired.'
  end

  def updateReset
    @user = User.find_signed(params[:token], purpose: 'password_reset')
    if @user.update(reset_password_params)
      redirect_to root_path, notice: 'Your password has been changed.'
    else
      render editReset
    end
  end

  def password_params
    params.permit(:old_password, :password, :password_confirmation)
  end

  def reset_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
