# Signed, expiring links to private uploads (see PrivateFilesController).
# Only render these where the viewer is already allowed to see the file.
module PrivateFilesHelper
  PURPOSE = :private_file
  EXPIRES_IN = 1.hour

  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.key_generator.generate_key("private_files"), url_safe: true
    )
  end

  def self.token_for(attachment, expires_in: EXPIRES_IN)
    verifier.generate(attachment.id, purpose: PURPOSE, expires_in:)
  end

  def self.verify(token)
    verifier.verified(token.to_s, purpose: PURPOSE)
  end

  def private_file_link(attachment, expires_in: EXPIRES_IN)
    Rails.application.routes.url_helpers.private_file_path(token: PrivateFilesHelper.token_for(attachment, expires_in:))
  end
end
