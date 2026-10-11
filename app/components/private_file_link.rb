# A link to a private upload through a signed, expiring URL (see
# PrivateFilesController). Only render it where the viewer may see the file.
class PrivateFileLink < Plutonium::UI::Component::Base
  include PrivateFilesHelper

  def initialize(attachment:, empty: "None")
    @attachment = attachment
    @empty = empty
  end

  def view_template
    unless @attachment&.attached?
      span(class: "text-[var(--pu-text-muted)]") { @empty }
      return
    end

    a(href: private_file_link(@attachment), target: "_blank", rel: "noopener",
      class: "inline-flex items-center gap-2 font-medium text-primary-600 hover:underline dark:text-primary-400") do
      render Phlex::TablerIcons::FileText.new(class: "h-4 w-4")
      plain @attachment.filename
    end
  end
end
