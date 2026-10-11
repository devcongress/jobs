# Country and currency lists for pickers. Countries are stored by their common
# English name ("Ghana"), so existing text, search and display keep working.
module World
  COMMON_CURRENCIES = %w[USD EUR GBP GHS NGN KES ZAR XOF EGP].freeze

  def self.country_names
    @country_names ||= ISO3166::Country.all.map(&:common_name).sort.freeze
  end

  # "Ghana" -> "GH", for structured data that wants ISO 3166 codes.
  def self.country_code(name)
    @country_codes ||= ISO3166::Country.all.to_h { |country| [country.common_name, country.alpha2] }.freeze
    @country_codes[name]
  end

  # The common ones first, then every other ISO 4217 code in use.
  def self.currency_codes
    @currency_codes ||= (COMMON_CURRENCIES + ISO3166::Country.all.filter_map(&:currency_code).uniq.sort).uniq.freeze
  end

  def self.country_validation
    {inclusion: {in: ->(_) { country_names }, message: "isn't a country we know"}, allow_blank: true}
  end

  def self.currency_validation
    {inclusion: {in: ->(_) { currency_codes }, message: "isn't a currency we know"}}
  end
end
