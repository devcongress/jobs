module Network
  class EndorsementDefinition < Network::ResourceDefinition
    field :profile, label: "Developer"
    field :created_at, label: "Endorsed"
    default_sort :created_at, :desc
  end
end
