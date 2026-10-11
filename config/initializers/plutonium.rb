# Configure plutonium

# Portal page titles; otherwise Plutonium uses the app module name (DevRegistry).
Plutonium.application_name = "DevCongress Connect"

Plutonium.configure do |config|
  config.load_defaults 1.0

  # Shell variant: :modern (icon rail), :plain (no rail), or :classic (legacy).
  config.shell = :modern
  config.assets.stylesheet = "application"
  config.assets.script = "application"
  config.assets.logo = "brand/devcongress-dev-square.png"
  config.assets.favicon = "brand/devcongress-dev-square.png"
  # Configure plutonium above.
end
