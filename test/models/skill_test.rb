require "test_helper"

class SkillTest < ActiveSupport::TestCase
  GENERIC_SKILL_FRAMING = /\b(?:great skill|(?:is|are) (?:a|an) [^.]*\bskill)\b/i
  LICENSING_AS_DESCRIPTION = /\bopen[- ]source\b/i

  PUBLIC_DIRECTORY_SKILLS = [
    "AI strategy", "Amazon Web Services (AWS)", "Angular", "Apache Kafka", "Astro", "Backend development",
    "Bootstrap", "C", "C#", "C++", "C++/CLI", "Dart", "DevOps", "Django", "Express.js", "Firebase",
    "Flutter", "Frontend development", "Go", "Graphic design", "HTML", "Java", "JavaScript", "Kotlin",
    "Laravel", "Laravel Livewire", "Large language models (LLMs)", "MongoDB", "MySQL", "Next.js", "Node.js",
    "PHP", "PL/SQL", "PostgreSQL", "Product management", "Progressive web apps", "Prompt engineering", "Python",
    "REST APIs", "RabbitMQ", "React", "React Native", "Redis", "Responsive web design", "Ruby", "Ruby on Rails",
    "Rust", "SQL", "Scala", "Spring Boot", "Spring Framework", "Supabase", "Tailwind CSS", "TanStack Query",
    "TypeScript", "Vite", "Web application development", "WordPress", "Zig", "Hotwire"
  ].freeze

  test "derives a slug and rejects duplicate names" do
    assert_equal "ruby-on-rails", Skill.create!(name: " Ruby  on Rails ").slug
    assert_not Skill.new(name: "ruby on rails").valid?
  end

  test "provides canonical copy for curated and category-backed skills" do
    curated = Skill.new(name: "React", category: "Frontend", description: "Curated React description.")
    generated = Skill.new(name: "Elixir", category: "Languages")
    uncategorised = Skill.new(name: "A new tool")

    assert_equal "Curated React description.", curated.canonical_description
    assert_includes generated.canonical_description, "Elixir"
    assert_includes generated.canonical_description, "Elixir lets developers"
    assert_includes uncategorised.canonical_description, "design, build or operate"
    assert_includes generated.canonical_why_description, "Working with Elixir"
    [generated.canonical_description, generated.canonical_why_description, uncategorised.canonical_description].each do |copy|
      assert_no_match GENERIC_SKILL_FRAMING, copy
    end
  end

  test "every seeded skill category has a description template" do
    catalogue = YAML.load_file(Rails.root.join("db/seeds/skills.yml"))

    assert_equal catalogue.keys, SkillDescription.categories
    catalogue.each_value do |content|
      assert content.values_at("description", "why_description", "skills").all?(&:present?)
      assert_includes content.fetch("description"), "%{name}"
      assert_includes content.fetch("why_description"), "%{name}"
      assert_no_match GENERIC_SKILL_FRAMING, content.fetch("description")
      assert_no_match GENERIC_SKILL_FRAMING, content.fetch("why_description")
    end
  end

  test "curated seed descriptions belong to catalogue skills" do
    catalogue = YAML.load_file(Rails.root.join("db/seeds/skills.yml"))
    catalogue_slugs = catalogue.values.flat_map { |content| content.fetch("skills") }.map { |name| Skill.slug_for(name) }
    descriptions = YAML.load_file(Rails.root.join("db/seeds/skill_descriptions.yml"))

    assert_empty descriptions.keys - catalogue_slugs
    assert_empty PUBLIC_DIRECTORY_SKILLS.map { |name| Skill.slug_for(name) } - descriptions.keys
    descriptions.each_value do |content|
      assert content.values_at("description", "website_url", "why_description").all?(&:present?)
      assert_no_match GENERIC_SKILL_FRAMING, content.fetch("description")
      assert_no_match GENERIC_SKILL_FRAMING, content.fetch("why_description")
      assert_no_match LICENSING_AS_DESCRIPTION, content.fetch("description")
      assert_match WebUrl::FORMAT, content.fetch("website_url")
      assert_match WebUrl::FORMAT, content.fetch("source_url") if content["source_url"].present?
      assert content.fetch("company_examples").present?
      assert content.fetch("company_examples").all? do |example|
        example.values_at("name", "url").all?(&:present?) && example.fetch("url").match?(WebUrl::FORMAT)
      end
    end
    assert_match %r{\Ahttps://github\.com/}, descriptions.fetch("react").fetch("source_url")
    assert_equal "https://hotwired.dev/", descriptions.fetch("hotwire").fetch("website_url")
    assert_equal "https://github.com/hotwired", descriptions.fetch("hotwire").fetch("source_url")
    assert_empty %w[hotwire javascript postgresql ruby ruby-on-rails] - descriptions.keys
  end

  test "company examples require linked references" do
    skill = Skill.new(name: "React", company_examples: [{"name" => "Acme"}])

    assert_not skill.valid?
    assert_includes skill.errors[:company_examples], "must include a name and http(s) source link for each company"
  end

  test "curated content cannot be marked complete while required copy is missing" do
    skill = Skill.new(name: "React", content_curated: true)

    assert_not skill.valid?
    assert_includes skill.errors[:content_curated], "requires description, website, why it matters and company references"
  end
end
