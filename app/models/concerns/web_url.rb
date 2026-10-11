# Only http(s) URLs are accepted for links we render as <a href>, so nobody can
# store a javascript: or data: URL.
module WebUrl
  FORMAT = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/

  def self.validation
    {format: {with: FORMAT, message: "must be a full http:// or https:// address"}, allow_blank: true}
  end
end
