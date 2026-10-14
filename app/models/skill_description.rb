class SkillDescription
  CATALOGUE_PATH = Rails.root.join("db/seeds/skills.yml")

  DEFAULT_CONTENT = {
    "description" => "Developers use %{name} to design, build or operate digital products and systems.",
    "why_description" => "Experience with %{name} helps teams deliver software that is reliable and maintainable."
  }.freeze

  def self.catalogue = @catalogue ||= YAML.load_file(CATALOGUE_PATH).freeze

  def self.categories = catalogue.keys

  def self.description_for(name:, category:)
    format(content_for(category).fetch("description"), name:)
  end

  def self.why_for(name:, category:)
    format(content_for(category).fetch("why_description"), name:)
  end

  def self.content_for(category)
    catalogue.fetch(category, DEFAULT_CONTENT)
  end
  private_class_method :content_for
end
