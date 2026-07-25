# Register our custom Structured Text lexer with Rouge so ```st code fences in
# markdown lessons get highlighted. lib/ isn't autoloaded, and the lexer must be
# defined before the first markdown render, so require it here at boot.
require "rouge"
require Rails.root.join("lib/rouge/lexers/structured_text")
