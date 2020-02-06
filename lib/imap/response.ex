defmodule Imap.Response do
  @moduledoc ~S"""
  Parse responses returned by the IMAP server and convert them to a structured format
  """

  def parse(type, {%Imap.Client{}, response}) do
    parse(type, response)
  end

  def parse(type, {:ok, [response: response], "", _, _, _}) do
    parse(type, response)
  end

  def parse(type, parts) when type in [:select, :examine] do
    {:ok, Enum.map(parts, &parse_list_part/1)}
  end

  def parse(
        :fetch,
        [
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
          | _
        ]
      ) do
    {:ok, msg_att_static |> parse_msg_att_static() |> Mail.Parsers.RFC2822.parse()}
  end

  defp parse_list_part(
         {:response_data, ["*", " ", {:mailbox_data, [{:number, number}, " ", property]}, _]}
       ) do
    {property, number}
  end

  defp parse_list_part(
         {:response_data, ["*", " ", {:mailbox_data, ["FLAGS", " ", {:flag_list, flags}]}, _]}
       ) do
    {:flags, Enum.reject(flags, &is_binary/1)}
  end

  defp parse_list_part(
         {:response_data, ["*", " ", {:resp_cond_state, ["OK", " ", {:resp_text, data}]}, _]}
       ) do
    data
  end

  defp parse_list_part(
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
