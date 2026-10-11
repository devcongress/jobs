# Serves private uploads (CVs and the like). Files live outside public/, and the
# only way in is a short-lived signed link from PrivateFilesHelper, which pages
# render after their own authorization checks.
class PrivateFilesController < ApplicationController
  INLINE_TYPES = %w[application/pdf].freeze

  def show
    attachment = ActiveShrine::Attachment.find_by(id: PrivateFilesHelper.verify(params[:token]))
    return head :not_found unless attachment&.file

    response.headers["Cache-Control"] = "private, no-store"
    response.headers["X-Robots-Tag"] = "noindex"
    content_type = attachment.content_type.presence || "application/octet-stream"
    attachment.file.open do |io|
      send_data io.read,
        filename: attachment.filename.presence || "download",
        type: content_type,
        disposition: INLINE_TYPES.include?(content_type) ? "inline" : "attachment"
    end
  end
end
