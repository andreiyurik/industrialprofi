# Animated lesson schemes: curated ERB + CSS in the repo, placed as `![alt](diagram:<slug>)`.
class Diagram
  SLUGS = %w[
    current-loop
    switch-circuits
    plc-scan
    rcd-leak
    cabinet-signal
    ld-ton
    pid-response
    rs485-modbus
    fault-loop
  ].freeze
  SRC = /\Adiagram:(?<slug>[a-z0-9-]+)\z/

  def self.slug(src)
    slug = src.to_s[SRC, :slug]
    slug if SLUGS.include?(slug)
  end

  # Rendered lessons are cached, and template digests don't reach a helper cache.
  def self.version
    @version = nil if Rails.env.development?
    @version ||= Digest::MD5.hexdigest(
      Dir[Rails.root.join("{app/views/diagrams/*,config/locales/diagrams/*}")].sort.map { File.read(it) }.join)
  end
end
