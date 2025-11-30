# frozen_string_literal: true

# SMS Service for sending OTP codes
# Replace this with your actual SMS provider (Twilio, AWS SNS, etc.)
class SmsService
  def self.send_otp(phone_number, code)
    # TODO: Replace with actual SMS service integration
    # Example with Twilio:
    # client = Twilio::REST::Client.new(account_sid, auth_token)
    # client.messages.create(
    #   from: '+1234567890',
    #   to: phone_number,
    #   body: "Your OTP code is: #{code}"
    # )

    # For development/testing, just log the OTP
    Rails.logger.info "SMS OTP to #{phone_number}: #{code}"

    # In production, uncomment and configure your SMS service:
    # send_via_twilio(phone_number, code)
    # or
    # send_via_aws_sns(phone_number, code)

    true
  end

  private

  # Example Twilio implementation
  # def self.send_via_twilio(phone_number, code)
  #   client = Twilio::REST::Client.new(
  #     Rails.application.credentials.twilio_account_sid,
  #     Rails.application.credentials.twilio_auth_token
  #   )
  #   client.messages.create(
  #     from: Rails.application.credentials.twilio_phone_number,
  #     to: phone_number,
  #     body: "Your verification code is: #{code}"
  #   )
  # end
end
