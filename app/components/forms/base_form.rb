module Forms
  # Plutonium's themed form (Phlexi underneath) for pages outside the resource
  # CRUD flow, so they share the portals' inputs, labels, hints and errors.
  class BaseForm < Plutonium::UI::Form::Base
    def initialize(object, submit_label:, cancel_url: nil, **options)
      @submit_label = submit_label
      @cancel_url = cancel_url
      super(object, **options)
    end

    private

    # Rendered inside the onboarding card, so drop the form's own card chrome
    # (same approach as Plutonium's wizard form).
    def form_class
      "space-y-6"
    end

    # The resource forms' wrapper assumes a page card; these render inside
    # the onboarding card, so drop the extra chrome.
    def fields_wrapper(&)
      div(class: "grid grid-cols-1 gap-4 sm:grid-cols-2", &)
    end

    def render_actions
      div(class: "flex gap-3 pt-2") do
        button(type: :submit, class: tokens("pu-btn pu-btn-md pu-btn-primary", @cancel_url ? nil : "w-full")) { @submit_label }
        a(href: @cancel_url, class: "pu-btn pu-btn-md pu-btn-outline") { "Cancel" } if @cancel_url
      end
    end

    # `required:` only drives the label's asterisk. The browser's own required
    # check is left off because some fields sit in sections that can be hidden;
    # the models validate them.
    def text(name, span: false, **options)
      render field(name, **options).wrapped(class: span_class(span)) { |f| render f.input_tag(required: false) }
    end

    def url(name, span: false, **options)
      render field(name, **options).wrapped(class: span_class(span)) { |f| render f.url_tag(placeholder: "https://", required: false) }
    end

    def country(name, **options)
      render field(name, placeholder: "Choose a country", **options).wrapped do |f|
        render f.slim_select_tag(choices: World.country_names)
      end
    end

    def span_class(span) = span ? "sm:col-span-2" : nil

    def section(**attributes, &)
      div(**attributes, class: tokens("space-y-4", attributes[:class]), &)
    end
  end
end
