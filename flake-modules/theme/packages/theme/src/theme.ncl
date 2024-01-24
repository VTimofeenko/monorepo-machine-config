let rawData = import "./modus_custom.ncl" in
let hexHelpers = {
  hexToDecMap = {
    a = 10,
    b = 11,
    c = 12,
    d = 13,
    e = 14,
    f = 15
  },
  firstChar = fun _v => _v |> std.string.lowercase |> std.string.characters |> std.array.first |> charToNum |> (*) 16,
  lastChar = fun _v => _v |> std.string.lowercase |> std.string.characters |> std.array.last |> charToNum,
  charToNum = fun char => if (std.string.is_match "\\d" char) then std.string.to_number char else hexToDecMap."%{char}",
  convert = fun hex => [firstChar, lastChar] |> std.array.map (fun f => f hex) |> std.array.reduce_left (+)
}
in
{
  scheme =
    rawData
    |> std.record.map
      (
        fun colorName hexValue =>
          let colorNumber = (std.string.find "\\d+$" colorName).matched
          in
          {
            hex = hexValue,
            "#hex" = "#%{hexValue}",
            name = colorName,
            r = hexHelpers.convert (std.string.substring 0 2 hexValue),
            g = hexHelpers.convert (std.string.substring 2 4 hexValue),
            b = hexHelpers.convert (std.string.substring 4 6 hexValue),
            HEX = hexValue |> std.string.uppercase,
            "#HEX" = "#%{hexValue}" |> std.string.uppercase,
          }
          & (if colorNumber != "" then { number = colorNumber } else {})
      ),
  semantic =
    {
      activeFrameBorder = scheme.cyan-intense,
      inactiveFrameBorder = scheme.border-mode-line-inactive,
      levelInfo = scheme.color4,
      levelWarn = scheme.color3,
      levelErr = scheme.color1,
      comment = scheme.color7,
    }
    |> std.record.map (fun colorName colorValue => colorValue |> std.record.update "origName" colorValue.name |> std.record.update "name" colorName),
}