defmodule Imap.Response do
  @moduledoc ~S"""
  Parse responses returned by the IMAP server and convert them to a structured format
  """

  def parse({%Imap.Client{}, response}) do
    parse(response)
  end

  def parse({:ok, [response: response], "", _, _, _}) do
    parse(response)
  end

  def parse(parts) do
    {:ok, Enum.map(parts, &parse_message_data/1)}
  end

  defp parse_message_data(
         {:response_data, ["*", " ", {:mailbox_data, [{:number, number}, " ", property]}, _]}
       ) do
    {property, number}
  end

  defp parse_message_data(
         {:response_data, ["*", " ", {:mailbox_data, ["FLAGS", " ", {:flag_list, flags}]}, _]}
       ) do
    {:flags, Enum.reject(flags, &is_binary/1)}
  end

  defp parse_message_data(
         {:response_data, ["*", " ", {:resp_cond_state, ["OK", " ", {:resp_text, data}]}, _]}
       ) do
    data
  end

  defp parse_message_data(
         {:response_data,
          [
            "*",
            " ",
            {:message_data,
             [
               _index,
               " ",
               "FETCH",
               " ",
               {:msg_att,
                [
                  "(",
                  {:msg_att_static, msg_att_static},
                  ")"
                ]}
             ]}
            | _
          ]}
       ) do
    msg_att_static |> parse_msg_att_static() |> Mail.Parsers.RFC2822.parse()
  end

  defp parse_message_data(
         {:response_done,
          [response_tagged: [_tag, " ", {:resp_cond_state, ["OK", " ", {:resp_text, data}]}, _]]}
       ) do
    data
  end

  defp parse_msg_att_static(["RFC822", " ", {:literal, [_number, body]}]) do
    body
  end

  defp parse_msg_att_static(["BODY", _section, " ", {:literal, [_number, body]}]) do
    body
  end
end
