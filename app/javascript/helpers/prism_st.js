// Prism grammar for IEC 61131-3 Structured Text (PLC programming). Lexxy bundles
// Prism but not ST, and it highlights through the global `window.Prism`, so
// registering the grammar here lights up every `<pre data-language="st">` block —
// both live in the editor and in rendered rich text (highlightCode). No build step.
//
// Token order matters: earlier keys win, so comments/strings/time-literals come
// before words, keywords before the function-name catch-all.
export function registerStructuredText(prism = window.Prism) {
  if (!prism || prism.languages.st) return

  prism.languages.st = {
    comment: [
      { pattern: /\(\*[\s\S]*?\*\)/, greedy: true },
      { pattern: /\/\/.*/, greedy: true }
    ],
    string: {
      // ST strings use '…' (or "…" for WSTRING); $ is the escape char.
      pattern: /'(?:\$.|[^'$])*'|"(?:\$.|[^"$])*"/,
      greedy: true
    },
    // Duration/date literals: T#5s, TIME#1h30m, DT#2024-01-01-00:00:00, D#…
    "time-literal": {
      pattern: /\b(?:T|TIME|LT|LTIME|D|DATE|TOD|LTOD|DT|LDT)#[\w.:+-]+/i,
      alias: "number"
    },
    boolean: /\b(?:TRUE|FALSE)\b/i,
    number: /\b(?:16#[\da-f_]+|2#[01_]+|8#[0-7_]+|\d[\d_]*\.?[\d_]*(?:e[+-]?\d+)?)\b/i,
    keyword: /\b(?:IF|THEN|ELSIF|ELSE|END_IF|CASE|OF|END_CASE|FOR|TO|BY|DO|END_FOR|WHILE|END_WHILE|REPEAT|UNTIL|END_REPEAT|RETURN|EXIT|CONTINUE|FUNCTION|END_FUNCTION|FUNCTION_BLOCK|END_FUNCTION_BLOCK|METHOD|END_METHOD|PROGRAM|END_PROGRAM|VAR_INPUT|VAR_OUTPUT|VAR_IN_OUT|VAR_GLOBAL|VAR_TEMP|VAR_EXTERNAL|VAR_ACCESS|VAR_CONFIG|VAR_STAT|VAR|CONSTANT|RETAIN|NON_RETAIN|END_VAR|TYPE|END_TYPE|STRUCT|END_STRUCT|ARRAY|AT|WITH|CONFIGURATION|END_CONFIGURATION|RESOURCE|END_RESOURCE|TASK|ACTION|END_ACTION|STEP|END_STEP|TRANSITION|END_TRANSITION|INITIAL_STEP|EXTENDS|IMPLEMENTS|INTERFACE|END_INTERFACE)\b/i,
    "class-name": {
      pattern: /\b(?:BOOL|BYTE|WORD|DWORD|LWORD|SINT|USINT|INT|UINT|DINT|UDINT|LINT|ULINT|REAL|LREAL|TIME|LTIME|DATE|TIME_OF_DAY|TOD|DATE_AND_TIME|DT|STRING|WSTRING|CHAR|WCHAR|POINTER|REF_TO|ANY|ANY_INT|ANY_REAL|ANY_NUM|ANY_BIT|ANY_DATE)\b/i,
      alias: "builtin"
    },
    function: /\b[A-Za-z_]\w*(?=\s*\()/,
    operator: /:=|=>|<>|<=|>=|\*\*|[-+*/<>=&]|\b(?:AND|OR|XOR|NOT|MOD)\b/i,
    punctuation: /[()[\].,;:]/
  }

  // Common aliases people write in fences / language pickers.
  prism.languages.iecst = prism.languages.st
  prism.languages["structured-text"] = prism.languages.st
}
