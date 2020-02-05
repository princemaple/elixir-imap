defmodule Imap.Parser do
  use AbnfParsec,
    abnf_file: "priv/imap.abnf",
    transform: %{
      "text" => {:reduce, {List, :to_string, []}},
      "atom" => {:reduce, {List, :to_string, []}},
      "nz-number" => {:reduce, {List, :to_string, []}}
    },
    unbox: [
      "TEXT-CHAR",
      "ATOM-CHAR",
      "ASTRING-CHAR",
      "resp-text-code",
      "text",
      "digit-nz",
      "nz-number"
    ],
    unwrap: ["flag"]
end
