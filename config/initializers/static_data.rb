require 'yaml'

module StaticData
  mattr_reader :data, instance_reader: false

  def self.initialize!
    path = File.join(Rails.root, "app/lib/static_data/data.yml")
    data = YAML.load_file(path)
    @@data = data[:static_data]
  end

  def self.[](key)
    @@data[key]&.[](:values)
  end
end

StaticData.initialize!
