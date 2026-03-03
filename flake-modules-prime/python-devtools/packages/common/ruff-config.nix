/**
  Contains configuration for ruff as a package
*/
{
  formats,
  ...
}:
let
  settingsFormat = formats.toml { };
in
settingsFormat.generate "ruff.toml" {
  line-length = 120;
  format.quote-style = "double";
  lint = {
    select = [
      "A" # flake builtins
      "D" # Docstyle checker, very angry
      "N" # PEP8-naming
      "TID" # for banned inputs
      "Q" # quotes
      "E111" # Indentation is not a multiple of {indent_size}
      "E113" # Unexpected indentation
      "E117" # Over-indented (comment)
      "E201" # Whitespace after '{symbol}'
      "E202" # Whitespace before '{symbol}'
      "E203" # Whitespace before '{symbol}'
      "E211" # Whitespace before '{bracket}'
      "E221" # Multiple spaces before operator
      "E222" # Multiple spaces after operator
      "E225" # Missing whitespace around operator
      "E226" # Missing whitespace around arithmetic operator
      "E227" # Missing whitespace around bitwise or shift operator
      "E228" # Missing whitespace around modulo operator
      "E231" # Missing whitespace after '{token}'
      "E241" # Multiple spaces after comma
      "E242" # Tab after comma
      "E251" # Unexpected spaces around keyword / parameter equals
      "E252" # Missing whitespace around parameter equals
      "E261" # Insert at least two spaces before an inline comment
      "E262" # Inline comment should start with #
      "E265" # Block comment should start with #
      "E266" # Too many leading # before block comment
      "E271" # Multiple spaces after keyword
      "E272" # Multiple spaces before keyword
      "E275" # Missing whitespace after keyword
      "E301" # Expected {BLANK_LINES_NESTED_LEVEL:?} blank line, found 0
      "E302" # Expected {expected_blank_lines:?} blank lines, found {actual_blank_lines}
      "E303" # Too many blank lines ({actual_blank_lines})
      "E304" # Blank lines found after function decorator ({lines})
      "E305" # Expected 2 blank lines after class or function definition, found ({blank_lines})
      "E306" # Expected 1 blank line before a nested definition, found 0
      "E501" # Line too long ({width} > {limit})
      "E703" # Statement ends with an unnecessary semicolon
      "E711" # Comparison to None should be `cond is None`
      "E712" # Avoid equality comparisons to True; use `if {cond}:` for truth checks
      "E713" # Test for membership should be not in
      "E714" # Test for object identity should be is not
      "E721" # Do not compare types, use `isinstance()`
      "E722" # Do not use bare except
      "I" # `isort`
    ];
    pydocstyle.convention = "pep257";
  };
}
