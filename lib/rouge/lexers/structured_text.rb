# Rouge lexer for IEC 61131-3 Structured Text (PLC programming) — the markdown
# half of ST highlighting (the editor/rich-text half is the Prism grammar in
# app/javascript/helpers/prism_st.js). kramdown looks a lexer up by the fence
# language, so ```st in a lesson gets tokenized here. Defining the class with
# `tag "st"` auto-registers it with Rouge (see Rouge::Lexer.tag).
#
# `st` is Smalltalk's alias in stock Rouge; we deliberately claim it for
# Structured Text, which is the only "st" our content uses.
module Rouge
  module Lexers
    class StructuredText < RegexLexer
      title "Structured Text"
      desc "IEC 61131-3 Structured Text (PLC programming)"
      tag "st"
      aliases "iecst", "structured-text"

      state :root do
        rule %r{\s+}m, Text::Whitespace
        rule %r{\(\*.*?\*\)}m, Comment::Multiline
        rule %r{//.*}, Comment::Single
        rule %r{'(?:\$.|[^'$])*'}, Str::Single
        rule %r{"(?:\$.|[^"$])*"}, Str::Double

        # Duration/date literals: T#5s, TIME#1h30m, DT#2024-01-01-00:00:00.
        rule %r{\b(?:T|TIME|LT|LTIME|D|DATE|TOD|LTOD|DT|LDT)#[\w.:+-]+}i, Num::Other
        rule %r{\b(?:TRUE|FALSE)\b}i, Keyword::Constant
        rule %r{\b(?:16#[\h_]+|2#[01_]+|8#[0-7_]+)\b}i, Num::Hex
        rule %r{\b\d[\d_]*\.\d[\d_]*(?:e[+-]?\d+)?\b}i, Num::Float
        rule %r{\b\d[\d_]*\b}, Num::Integer

        rule %r{\b(?:IF|THEN|ELSIF|ELSE|END_IF|CASE|OF|END_CASE|FOR|TO|BY|DO|END_FOR|WHILE|END_WHILE|REPEAT|UNTIL|END_REPEAT|RETURN|EXIT|CONTINUE|FUNCTION|END_FUNCTION|FUNCTION_BLOCK|END_FUNCTION_BLOCK|METHOD|END_METHOD|PROGRAM|END_PROGRAM|VAR_INPUT|VAR_OUTPUT|VAR_IN_OUT|VAR_GLOBAL|VAR_TEMP|VAR_EXTERNAL|VAR_ACCESS|VAR_CONFIG|VAR_STAT|VAR|CONSTANT|RETAIN|NON_RETAIN|END_VAR|TYPE|END_TYPE|STRUCT|END_STRUCT|ARRAY|AT|WITH|CONFIGURATION|END_CONFIGURATION|RESOURCE|END_RESOURCE|TASK|ACTION|END_ACTION|STEP|END_STEP|TRANSITION|END_TRANSITION|INITIAL_STEP|EXTENDS|IMPLEMENTS|INTERFACE|END_INTERFACE)\b}i, Keyword

        rule %r{\b(?:BOOL|BYTE|WORD|DWORD|LWORD|SINT|USINT|INT|UINT|DINT|UDINT|LINT|ULINT|REAL|LREAL|TIME|LTIME|DATE|TIME_OF_DAY|TOD|DATE_AND_TIME|DT|STRING|WSTRING|CHAR|WCHAR|POINTER|REF_TO|ANY|ANY_INT|ANY_REAL|ANY_NUM|ANY_BIT|ANY_DATE)\b}i, Keyword::Type

        rule %r{\b(?:AND|OR|XOR|NOT|MOD)\b}i, Operator::Word
        rule %r{:=|=>|<>|<=|>=|\*\*|[-+*/<>=&]}, Operator
        rule %r{[A-Za-z_]\w*(?=\s*\()}, Name::Function
        rule %r{[A-Za-z_]\w*}, Name
        rule %r{[()\[\].,;:]}, Punctuation
      end
    end
  end
end
