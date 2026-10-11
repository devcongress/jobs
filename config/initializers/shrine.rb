# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require "shrine"
require "shrine/storage/file_system"

Shrine.logger = Rails.logger

# Uploads are PRIVATE: they live under storage/ (a persistent Kamal volume in
# production), never under public/, so the web server can't serve them. They
# are only reachable through PrivateFilesController, via short-lived signed
# links that pages hand out after their own authorization checks.
uploads_root = Rails.env.test? ? Rails.root.join("tmp/storage/uploads") : Rails.root.join("storage/uploads")

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new(uploads_root.join("cache")), # temporary
  store: Shrine::Storage::FileSystem.new(uploads_root.join("store")) # permanent
}

Shrine.plugin :activerecord
Shrine.plugin :determine_mime_type, analyzer: lambda { |io, analyzers|
  mime_type = analyzers[:marcel].call(io)
  mime_type = analyzers[:file].call(io) if mime_type == "application/octet-stream" || mime_type.nil?
  mime_type = analyzers[:mime_types].call(io) if mime_type == "text/plain"
  mime_type
}
Shrine.plugin :instrumentation
Shrine.plugin :infer_extension, force: true
Shrine.plugin :pretty_location
Shrine.plugin :refresh_metadata

Shrine.plugin :backgrounding

Shrine::Attacher.promote_block do
  PromoteShrineAttachmentJob.perform_later(self.class.name, record.class.name, record.id, record.record_type, name.to_s, file_data)
end

Shrine::Attacher.destroy_block do
  DestroyShrineAttachmentJob.perform_later(self.class.name, record.record_type, data)
end

# No upload_endpoint: direct uploads would let anyone write to the cache.
# Files arrive with the form submission instead.
