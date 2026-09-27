require "yaml"

# The demo's whole dataset, read once from data/sample.yml: the standards by
# department and the invented restaurants with their visits. Nothing here is
# written back; the app has no database.
module Sample
  PATH = Rails.root.join("data/sample.yml")

  class << self
    def departments = data.fetch(:departments)
    def restaurants = data.fetch(:restaurants)
    def standards = departments.flat_map(&:standards)

    def department(key) = departments.find { |d| d.key == key }
    def standard(id) = standards.find { |s| s.id == id }
    def restaurant(slug) = restaurants.find { |r| r.slug == slug }

    private

    def data
      @data ||= parse(YAML.safe_load_file(PATH))
    end

    def parse(raw)
      departments = raw.fetch("departments").map do |d|
        standards = d.fetch("standards").map do |s|
          Standard.new(id: s.fetch("id"), text: s.fetch("text"), department_key: d.fetch("key"))
        end
        Department.new(key: d.fetch("key"), name: d.fetch("name"), standards: standards.freeze)
      end
      # Departments first: a visit scores every standard as it loads.
      @data = { departments: departments.freeze, restaurants: [] }
      @data[:restaurants] = raw.fetch("restaurants").map { |r| Restaurant.from_h(r) }.freeze
      @data
    end
  end
end
