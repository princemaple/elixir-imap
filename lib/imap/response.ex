defmodule Imap.Response do
  @moduledoc ~S"""
  Extract response info returned by the IMAP server and convert them to a structured format
  """

  def extract({%Imap.Client{}, response}) do
    extract(response)
  end

  def extract({:ok, [response: response], "", _, _, _}) do
    extract(response)
  end

  def extract(parts) do
    {:ok, Enum.map(parts, &extract_message_data/1)}
  end

  defp extract_message_data(
         {:response_data, ["*", {:mailbox_data, [{:number, number}, property]}]}
       ) do
    {property, number}
  end

  defp extract_message_data(
         {:response_data, ["*", {:mailbox_data, ["FLAGS", {:flag_list, flags}]}]}
       ) do
    {:flags, Enum.reject(flags, &is_binary/1)}
  end

  defp extract_message_data(
         {:response_data,
          [
            "*",
            {:mailbox_data,
             [
               "LIST",
               {:mailbox_list, ["(", {:mbx_list_flags, flags}, ")", scope, {:mailbox, name}]}
             ]}
          ]}
       ) do
    {scope, name, extract_mbx_flags(flags)}
  end

  defp extract_message_data(
         {:response_data, ["*", {:resp_cond_state, ["OK", {:resp_text, message}]}]}
       ) do
    message
  end

  defp extract_message_data(
         {:response_data,
          [
            "*",
            {:message_data,
             [_index, "FETCH", {:msg_att, ["(", {:msg_att_static, msg_att_static}, ")"]}]}
            | _
          ]}
       ) do
    msg_att_static |> extract_msg_att_static() |> Mail.Parsers.RFC2822.parse()
  end

  defp extract_message_data(
         {:response_done,
          [response_tagged: [tag, {:resp_cond_state, ["OK", {:resp_text, message}]}]]}
       ) do
    {tag, message}
  end

  defp extract_msg_att_static(["RFC822", {:literal, [_number, body]}]) do
    body
  end

  defp extract_msg_att_static(["BODY", _section, {:literal, [_number, body]}]) do
    body
  end

  defp extract_mbx_flags(flags) do
    Enum.map(flags, &extract_mbx_flag/1)
  end

  defp extract_mbx_flag({:mbx_list_oflag, [flag_extension: ["\\", {:atom, flag}]]}) do
    flag
  end
end
