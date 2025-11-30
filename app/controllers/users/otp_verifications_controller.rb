# frozen_string_literal: true

module Users
  class OtpVerificationsController < ApplicationController
    include RackSessionsFix
    respond_to :json

    # POST /users/otp_verifications/request
    def request_otp
      phone_number = params[:phone_number]
      email = params[:email]

      if phone_number.blank? && email.blank?
        render json: {
          status: {
            code: 422,
            message: 'Phone number or email is required'
          }
        }, status: :unprocessable_entity
        return
      end

      # Check if user already exists
      existing_user = User.find_by(phone_number: phone_number) if phone_number.present?
      existing_user ||= User.find_by(email: email) if email.present?

      if existing_user
        render json: {
          status: {
            code: 422,
            message: 'User with this phone number or email already exists'
          }
        }, status: :unprocessable_entity
        return
      end

      # Generate OTP verification
      otp_verification = OtpVerification.generate_for(
        phone_number: phone_number,
        email: email
      )

      # Send OTP via SMS or Email
      if phone_number.present?
        ::SmsService.send_otp(phone_number, otp_verification.otp_code)
      elsif email.present?
        # For email, you could send via ActionMailer
        # For now, just log it (in production, send actual email)
        Rails.logger.info "Email OTP to #{email}: #{otp_verification.otp_code}"
      end

      render json: {
        status: {
          code: 200,
          message: 'OTP has been sent successfully.'
        },
        data: {
          verification_token: otp_verification.verification_token,
          # In production, don't send OTP in response. This is for testing only.
          otp_code: Rails.env.development? ? otp_verification.otp_code : nil
        }
      }, status: :ok
    end

    # POST /users/otp_verifications/verify
    def verify_otp
      verification_token = params[:verification_token]
      otp_code = params[:otp_code]

      if verification_token.blank? || otp_code.blank?
        render json: {
          status: {
            code: 422,
            message: 'Verification token and OTP code are required'
          }
        }, status: :unprocessable_entity
        return
      end

      otp_verification = OtpVerification.find_by(verification_token: verification_token)

      if otp_verification.nil?
        render json: {
          status: {
            code: 404,
            message: 'Invalid verification token'
          }
        }, status: :not_found
        return
      end

      if otp_verification.verify!(otp_code)
        render json: {
          status: {
            code: 200,
            message: 'OTP verified successfully.'
          },
          data: {
            verification_token: otp_verification.verification_token,
            verified: true
          }
        }, status: :ok
      else
        render json: {
          status: {
            code: 422,
            message: 'Invalid or expired OTP code'
          }
        }, status: :unprocessable_entity
      end
    end
  end
end
