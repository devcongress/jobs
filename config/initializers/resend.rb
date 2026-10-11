return unless Rails.env.production?

Resend.api_key = ENV["RESEND_API_KEY"]
