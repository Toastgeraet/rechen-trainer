extends Node

## Autoload `Session`: state that has to survive scene changes.
##
## The UI language follows the device locale automatically; strings live in
## `i18n/strings.csv`, and a missing language falls back to German
## (`internationalization/locale/fallback`).

## Range picked in the main menu, read by the shake-box game.
var number_range: NumberRange = NumberRange.from_id(NumberRange.UP_TO_10)
