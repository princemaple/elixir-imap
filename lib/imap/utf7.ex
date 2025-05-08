defmodule Imap.UTF7 do
  @moduledoc false

  def decode(str) do
    str
    |> do_decode([])
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp do_decode("", acc), do: acc

  defp do_decode("&-" <> rest, acc) do
    do_decode(rest, ["&" | acc])
  end

  defp do_decode(<<"&", rest::binary>>, acc) do
    {b64, rest2} = extract_b64(rest, [])

    decoded =
      b64
      |> String.replace(",", "/")
      |> pad_base64()
      |> Base.decode64!()
      |> :unicode.characters_to_binary(:utf16, :utf8)

    do_decode(rest2, [decoded | acc])
  end

  defp do_decode(<<char::utf8, rest::binary>>, acc) do
    do_decode(rest, [<<char::utf8>> | acc])
  end

  defp extract_b64("-" <> rest, acc), do: {acc |> Enum.reverse() |> to_string, rest}

  defp extract_b64(<<char, rest::binary>>, acc) do
    extract_b64(rest, [char | acc])
  end

  defp pad_base64(b64) do
    pad_len = rem(4 - rem(byte_size(b64), 4), 4)
    b64 <> String.duplicate("=", pad_len)
  end
end
