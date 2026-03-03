{ lib }:
let
  inherit (lib)
    toUpper
    toLower
    substring
    stringToCharacters
    elemAt
    foldl'
    mapAttrs
    ;

  hexToDecMap = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  hexToDec =
    hex:
    let
      chars = stringToCharacters (toLower hex);
      first = hexToDecMap.${elemAt chars 0};
      second = hexToDecMap.${elemAt chars 1};
    in
    first * 16 + second;

  # Matches Nickel's addFlippedFields
  addFlippedFields =
    res:
    res
    // {
      hex = mapAttrs (_: v: v.hex) res;
      "#hex" = mapAttrs (_: v: v."#hex") res;
      HEX = mapAttrs (_: v: v.HEX) res;
      "#HEX" = mapAttrs (_: v: v."#HEX") res;
    };

  mkTheme =
    rawData:
    let
      # Extract number from end of string (e.g. "base00" -> "00")
      extractNumber =
        str:
        let
          chars = stringToCharacters str;
          isDigit = c: builtins.match "[0-9]" c != null;
          # Simple digit extraction from end
          digits = foldl' (acc: c: if isDigit c then acc + c else "") "" chars;
        in
        if digits == "" then null else digits;

      scheme = mapAttrs (
        colorName: hexValue:
        let
          colorNumber = extractNumber colorName;
        in
        {
          hex = toLower hexValue;
          "#hex" = "#${toLower hexValue}";
          name = colorName;
          r = hexToDec (substring 0 2 hexValue);
          g = hexToDec (substring 2 4 hexValue);
          b = hexToDec (substring 4 6 hexValue);
          HEX = toUpper hexValue;
          "#HEX" = "#${toUpper hexValue}";
        }
        // (if colorNumber != null then { number = colorNumber; } else { })
      ) rawData;

      semanticRaw = {
        activeFrameBorder = scheme.cyan-intense;
        inactiveFrameBorder = scheme.border-mode-line-inactive;
        levelInfo = scheme.color4;
        levelWarn = scheme.color3;
        levelErr = scheme.color1;
        comment = scheme.color7;
        foundTextBg = scheme.color11;
        foundTextFg = scheme.color0;
        levelOK = scheme.color2;

        # UI Elements
        uiActiveBg = scheme.blue-intense;
        uiActiveFg = scheme.bg-main;
        uiInactiveBg = scheme.bg-dim;
        uiInactiveFg = scheme.fg-dim;
        uiHighlightBg = scheme.magenta-intense;
        uiHighlightFg = scheme.bg-main;
        uiStatusBg = scheme.color0;
        uiStatusFg = scheme.fg-dim;
      };

      semantic = mapAttrs (
        colorName: colorValue:
        colorValue
        // {
          origName = colorValue.name;
          name = colorName;
        }
      ) semanticRaw;
    in
    {
      inherit scheme semantic;
    }
    |> mapAttrs (_: addFlippedFields);
in
{
  inherit mkTheme;
}
