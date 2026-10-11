# Plutonium's layouts pull the form widget libraries (EasyMDE, SlimSelect,
# Flatpickr, intl-tel-input, Uppy styles, and Font Awesome 4 for EasyMDE's
# toolbar) from jsdelivr and Lato from Google
# Fonts. We bundle the widgets into application.js/css and self-host our own
# fonts (app/assets/fonts), so skip those external tags.
module Layouts
  module SelfHostedAssets
    private

    def render_external_styles
    end

    def render_external_scripts
    end

    def render_fonts
    end
  end
end
