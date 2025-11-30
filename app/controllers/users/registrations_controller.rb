# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    include RackSessionsFix
    respond_to :json

    before_action :verify_otp_token, only: [:create]
    before_action :configure_sign_up_params, only: [:create]

    private

    def respond_with(current_user, _opts = {})
      if resource.persisted?
        # Mark OTP verification as used (delete it)
        @otp_verification&.destroy

        render json: {
          status: { code: 200, message: 'Signed up successfully.' },
          data: UserSerializer.new(current_user).serializable_hash[:data][:attributes]
        }
      else
        render json: {
          status: { message: "User couldn't be created successfully. #{current_user.errors.full_messages.to_sentence}" }
        }, status: :unprocessable_entity
      end
    end
    # before_action :configure_sign_up_params, only: [:create]
    # before_action :configure_account_update_params, only: [:update]

    # GET /resource/sign_up
    # def new
    #   super
    # end

    # POST /resource
    # def create
    #   super
    # end

    # GET /resource/edit
    # def edit
    #   super
    # end

    # PUT /resource
    # def update
    #   super
    # end

    # DELETE /resource
    # def destroy
    #   super
    # end

    # GET /resource/cancel
    # Forces the session data which is usually expired after sign
    # in to be expired now. This is useful if the user wants to
    # cancel oauth signing in/up in the middle of the process,
    # removing all OAuth session data.
    # def cancel
    #   super
    # end

    protected

    def verify_otp_token
      verification_token = params[:verification_token] || params.dig(:user, :verification_token)

      if verification_token.blank?
        render json: {
          status: {
            code: 422,
            message: 'Verification token is required. Please verify OTP first.'
          }
        }, status: :unprocessable_entity
        return
      end

      @otp_verification = OtpVerification.find_by(verification_token: verification_token)

      if @otp_verification.nil?
        render json: {
          status: {
            code: 404,
            message: 'Invalid verification token'
          }
        }, status: :not_found
        return
      end

      unless @otp_verification.verified?
        render json: {
          status: {
            code: 422,
            message: 'OTP must be verified before signup'
          }
        }, status: :unprocessable_entity
        return
      end

      # Set phone_number and email from verified OTP
      if params[:user].present?
        params[:user][:phone_number] ||= @otp_verification.phone_number
        params[:user][:email] ||= @otp_verification.email
      else
        params[:phone_number] ||= @otp_verification.phone_number
        params[:email] ||= @otp_verification.email
      end
    end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[name phone_number email])
    end

    # If you have extra params to permit, append them to the sanitizer.
    def configure_account_update_params
      devise_parameter_sanitizer.permit(:account_update, keys: %i[name phone_number])
    end

    # The path used after sign up.
    # def after_sign_up_path_for(resource)
    #   super(resource)
    # end

    # The path used after sign up for inactive accounts.
    # def after_inactive_sign_up_path_for(resource)
    #   super(resource)
    # end
  end
end
