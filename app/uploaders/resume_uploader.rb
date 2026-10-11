# CVs attached to job applications. Stored privately (see config/initializers/shrine.rb).
class ResumeUploader < Shrine
  MAX_SIZE = 5.megabytes
  TYPES = {
    "application/pdf" => ".pdf",
    "application/msword" => ".doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx"
  }.freeze

  plugin :validation_helpers

  Attacher.validate do
    validate_max_size MAX_SIZE, message: "must be 5 MB or smaller"
    validate_mime_type TYPES.keys, message: "must be a PDF or Word document"
  end
end
