defmodule Imap.Parser do
  use AbnfParsec,
    abnf_file: "priv/imap.abnf",
    transform: %{
      "text" => {:reduce, {List, :to_string, []}},
      "atom" => {:reduce, {List, :to_string, []}},
      "nz-number" => {:reduce, {List, :to_string, []}},
      "tag" => {:reduce, {List, :to_string, []}},
      "mailbox" => {:reduce, {List, :to_string, []}},
      "number" => {:reduce, {List, :to_string, []}}
    },
    unbox: [
      "TEXT-CHAR",
      "ATOM-CHAR",
      "ASTRING-CHAR",
      "QUOTED-CHAR",
      "astring",
      "nstring",
      "string",
      "resp-text-code",
      "text",
      "quoted",
      "digit-nz",
      "nz-number",
      "CHAR8"
    ],
    unwrap: ["flag", "atom", "mailbox", "number"],
    skip: ["number", "literal"]

  defparsec :number,
            integer(min: 1) |> unwrap_and_tag(:number)

  defcombinatorp :literal_text,
                 repeat_while(ascii_char([{:not, 0}]), {:not_end, []})
                 |> string("\r\n")
                 |> reduce({List, :to_string, []})

  defparsec :literal,
            ignore(string("{"))
            |> parsec(:number)
            |> ignore(string("}"))
            |> ignore(parsec(:core_crlf))
            |> parsec(:literal_text)
            |> tag(:literal)

  defp not_end(<<"\r\n)\r\n", _::binary>>, context, _, _) do
    {:halt, context}
  end

  defp not_end(_, context, _, _) do
    {:cont, context}
  end
end
