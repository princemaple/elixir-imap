defmodule Blop.Parser do
  @moduledoc false

  @external_resource "priv/imap.abnf"

  use AbnfParsec,
    abnf_file: "priv/imap.abnf",
    transform: %{
      "text" => {:reduce, {List, :to_string, []}},
      "atom" => {:reduce, {List, :to_string, []}},
      "tag" => {:reduce, {List, :to_string, []}},
      "mailbox" => {:reduce, {List, :to_string, []}},
      "date-year" => {:reduce, {List, :to_string, []}},
      "date-day-fixed" => {:reduce, {List, :to_string, []}},
      "time" => {:reduce, {List, :to_string, []}},
      "zone" => {:reduce, {List, :to_string, []}},
      "quoted" => {:reduce, {List, :to_string, []}},
      "astring" => {:reduce, {List, :to_string, []}}
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
      "CHAR8",
      "nil"
    ],
    unwrap: [
      "flag",
      "atom",
      "mailbox",
      "number",
      "date-year",
      "date-month",
      "date-day-fixed",
      "time",
      "zone"
    ],
    skip: ["nz-number", "number", "literal"],
    ignore: ["SP", "CRLF", "DQUOTE"]

  defparsec :number,
            integer(min: 1) |> unwrap_and_tag(:number)

  defparsec :nz_number,
            integer(min: 1) |> unwrap_and_tag(:nz_number)

  defcombinatorp :literal_text,
                 repeat_while(ascii_char([{:not, 0}]), {:not_end_of_literal, []})
                 |> reduce({List, :to_string, []})

  defparsec :literal,
            ignore(string("{"))
            |> parsec(:number)
            |> ignore(string("}"))
            |> post_traverse({:set_literal_size, []})
            |> ignore(parsec(:crlf))
            |> parsec(:literal_text)
            |> tag(:literal)

  defp set_literal_size(rest, [number: number] = args, context, _, _) do
    {rest, args, Map.put(context, :literal_size, number)}
  end

  defp not_end_of_literal(_rest, %{literal_size: 0} = context, _, _) do
    {:halt, Map.delete(context, :literal_size)}
  end

  defp not_end_of_literal(_rest, %{literal_size: size} = context, _, _) when size > 0 do
    {:cont, %{context | literal_size: size - 1}}
  end
end
