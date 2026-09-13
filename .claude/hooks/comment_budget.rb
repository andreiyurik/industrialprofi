#!/usr/bin/env ruby
require "json"
require "open3"

LINE_COMMENT = {
  ".rb" => /\A\s*#(?![!{])/, ".rake" => /\A\s*#(?![!{])/, ".yml" => /\A\s*#/,
  ".js" => %r{\A\s*//}, ".erb" => /\A\s*<%#/
}
BLOCK_COMMENT = { ".js" => [ %r{\A\s*/\*}, %r{\*/} ], ".css" => [ %r{\A\s*/\*}, %r{\*/} ], ".scss" => [ %r{\A\s*/\*}, %r{\*/} ] }
DIRECTIVE = %r{frozen_string_literal|rubocop:|<%#\s*locals:|eslint-|@ts-|\A\s*//\s*(Lifecycle|Actions|Private)\s*\z}

def comment_lines(text, extension)
  inside_block = false

  text.to_s.each_line.select do |line|
    next false if line.match?(DIRECTIVE)

    if inside_block
      inside_block = !line.match?(BLOCK_COMMENT[extension][1])
      true
    elsif (opener, closer = BLOCK_COMMENT[extension]) && line.match?(opener)
      inside_block = !line.match?(closer)
      true
    else
      LINE_COMMENT[extension]&.match?(line)
    end
  end.map(&:strip)
end

def committed_version(path)
  root = ENV.fetch("CLAUDE_PROJECT_DIR", Dir.pwd)
  output, status = Open3.capture2("git", "show", "HEAD:#{path.delete_prefix("#{root}/")}", chdir: root, err: File::NULL)
  status.success? ? output : ""
end

input = JSON.parse($stdin.read)
tool_input = input.fetch("tool_input", {})
path = tool_input["file_path"].to_s
extension = File.extname(path)

exit 0 unless LINE_COMMENT.key?(extension) || BLOCK_COMMENT.key?(extension)
exit 0 if path.include?("/db/seeds/curriculum/") || path.include?("/.claude/")

before, after =
  case input["tool_name"]
  when "Write" then [ committed_version(path), tool_input["content"] ]
  else [ tool_input["old_string"], tool_input["new_string"] ]
  end

added = comment_lines(after, extension).size - comment_lines(before, extension).size
exit 0 if added < 2

puts JSON.generate(
  decision: "block",
  reason: <<~REASON
    comment-budget: this edit adds #{added} comment lines to #{File.basename(path)}.
    House rule (AGENTS.md → Comments): no comment by default; at most one line, only for a non-obvious why.
    Delete comments that restate the code or narrate the change; move rationale to the commit message or docs/decisions.
    If a line is truly load-bearing, keep it and say why in your summary.
  REASON
)
