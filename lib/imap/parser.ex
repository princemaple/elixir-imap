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
                 |> reduce({List, :to_string, []})

  defparsec :literal,
            ignore(string("{"))
            |> parsec(:number)
            |> ignore(string("}"))
            |> post_traverse({:set_literal_size, []})
            |> ignore(parsec(:core_crlf))
            |> parsec(:literal_text)
            |> tag(:literal)

  defp set_literal_size(_rest, [number: number] = args, context, _, _) do
    {args, Map.put(context, :literal_size, number)}
  end

  defp not_end(_rest, %{literal_size: 0} = context, _, _) do
    {:halt, Map.delete(context, :literal_size)}
  end

  defp not_end(_rest, %{literal_size: size} = context, _, _) when size > 0 do
    {:cont, %{context | literal_size: size - 1}}
  end
end
