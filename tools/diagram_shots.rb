# bin/rails runner tools/diagram_shots.rb SLUG OUT_DIR [seconds,...] [theme] [width] [checked_input_id,...]
slug, out, times, theme, width, checked = ARGV
abort "unknown diagram" unless Diagram::SLUGS.include?(slug)

FileUtils.mkdir_p(out)
theme ||= "dark"
width = (width || 720).to_i
# Manifest order, so the cascade matches the site's.
sheets = Rails.root.join("app/assets/stylesheets/application.scss").read.scan(/^@use "([^"]+)"/).flatten
wanted = %w[_reset colors base utilities scene animation diagrams] << "diagram-#{slug}"
css = (sheets & wanted).map { Rails.root.join("app/assets/stylesheets/#{it}.css").read }.join("\n")
doc = Nokogiri::HTML5.fragment(ApplicationController.render(partial: "diagrams/#{slug.underscore}"))
checked.to_s.split(",").each do |id|
  input = doc.at_css("##{id}") or abort "no input ##{id}"
  doc.css("input[name='#{input["name"]}']").each { it.remove_attribute("checked") }
  input["checked"] = "checked"
end
body = doc.to_html

(times || "0,2,4,6,8").split(",").each do |time|
  freeze = ".diagram *, .diagram *::before, .diagram *::after { animation-delay: calc(var(--delay, 0s) - #{Float(time)}s) !important; animation-play-state: paused !important; }"
  page = File.join(File.expand_path(out), "#{slug}.html")
  File.write(page, %(<!doctype html><html data-theme="#{theme}"><meta charset="utf-8"><style>#{css}\n#{freeze}\nbody{display:block;margin:0;padding:12px}main{inline-size:#{width}px}</style><body><main>#{body}</main></body></html>))
  shot = File.join(File.expand_path(out), "#{slug}-#{theme}-#{width}-#{checked.to_s.tr(",", "_")}-t#{time}.png")
  system("chromium", "--headless", "--no-sandbox", "--hide-scrollbars", "--window-size=#{[ width + 24, 500 ].max},#{(width * 0.9).to_i + 260}", "--screenshot=#{shot}", "file://#{page}", err: File::NULL, exception: true)
  puts shot
end
