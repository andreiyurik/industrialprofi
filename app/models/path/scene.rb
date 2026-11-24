# The loop diagram on a profession's overview: four steps round a circuit plus one watcher
# above it. Data in `paths.landing["scene"]`, so a curator fills a form, not a template.
class Path::Scene
  STEPS = 4
  LIMITS = { "name" => 24, "does" => 40, "link" => 24, "caption" => 200, "course" => 200 }.freeze

  Node = Struct.new(:name, :does, :icon, :course) do
    def emblem = icon.presence || Icon::DEFAULT_EMBLEM
  end

  class << self
    def normalize(data)
      shaped = shape(data)
      shaped if new(shaped).present?
    end

    # Form params arrive as index-keyed hashes, packs as arrays — both end up as arrays.
    # Anything that isn't the expected shape counts as empty, never as an error.
    def shape(data)
      data = hash(data)
      { "steps" => Array.new(STEPS) { |index| node(list(data["steps"])[index]) },
        "links" => Array.new(STEPS) { |index| clip(list(data["links"])[index], "link") },
        "top" => node(data["top"]).then { |top| top if top["name"].present? },
        "top_link" => clip(data["top_link"], "link"),
        "caption" => clip(data["caption"], "caption") }.compact_blank
    end

    private
      def hash(value) = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h.deep_stringify_keys : (value.is_a?(Hash) ? value.deep_stringify_keys : {})

      def list(value) = value.is_a?(Hash) ? value.sort_by { |index, _| index.to_i }.map(&:last) : Array(value)

      def node(data)
        data = hash(data)
        { "name" => clip(data["name"], "name"), "does" => clip(data["does"], "does"),
          "icon" => (data["icon"] if Icon.emblem?(data["icon"])), "course" => clip(data["course"], "course").presence }.compact_blank
      end

      def clip(text, limit) = (text.is_a?(String) || text.is_a?(Numeric) ? text.to_s : "").strip.first(LIMITS.fetch(limit))
  end

  def initialize(data)
    @data = data.to_h
  end

  def present? = named == STEPS
  def partial? = named.between?(1, STEPS - 1)
  def steps = Array.new(STEPS) { |index| build(Array(@data["steps"])[index]) }
  def links = Array.new(STEPS) { |index| Array(@data["links"])[index].to_s }
  def top = build(@data["top"])
  def top_link = @data["top_link"].to_s
  def caption = @data["caption"].to_s

  private
    def named = steps.count { |step| step.name.present? }

    def build(data) = Node.new(*data.to_h.values_at("name", "does", "icon", "course"))
end
