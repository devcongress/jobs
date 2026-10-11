module StructuredData
  class Project < Base
    def initialize(project, contributors:, view:)
      super(project, view:)
      @contributors = contributors
    end

    def to_h
      project = @record
      {
        "@context" => CONTEXT,
        "@type" => "CreativeWork",
        "name" => project.title,
        "description" => project.summary,
        "url" => view.public_project_url(project.slug),
        "author" => person(project.owner),
        "contributor" => @contributors.map { |profile| person(profile) },
        "keywords" => project.skills.map(&:name).join(", "),
        "sameAs" => [project.repo_url, project.demo_url].compact_blank
      }.compact_blank
    end
  end
end
