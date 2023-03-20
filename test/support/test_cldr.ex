defmodule Test.Cldr do
  use Cldr,
    default_locale: "en",
    locales: ["en", "de"],
    providers: [Cldr.Number, Cldr.Unit]
end
