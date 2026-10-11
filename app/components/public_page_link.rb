# Links a developer or project to its public page. Portal association links
# would point at the viewer's own portal, where other people's records don't
# exist.
class PublicPageLink < Plutonium::UI::Component::Base
  def initialize(record:)
    @record = record
  end

  def view_template
    label, href =
      case @record
      when Developers::Profile then ["#{@record.name} (@#{@record.handle})", main_app.developer_page_path(handle: @record.handle)]
      when Showcase::Project then [@record.title, main_app.public_project_path(@record.slug)]
      end

    if href
      a(href:, class: "font-medium text-primary-600 hover:underline dark:text-primary-400") { label }
    else
      span(class: "text-[var(--pu-text-muted)]") { "None" }
    end
  end
end
