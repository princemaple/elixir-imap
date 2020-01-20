defmodule Imap.Client do
  alias Imap.Request
  alias Imap.Response
  alias Imap.Socket

  alias __MODULE__

  defstruct [:conn, tag_number: 1]

  @moduledoc """
  Imap Client GenServer
  """

  @literal ~r/{([0-9]*)}\r\n/s

  def new(opts) do
    {host, opts} = Map.pop(opts, :incoming_mail_server)
    host = to_charlist(host)
    {port, opts} = Map.pop(opts, :incoming_port, 993)
    {username, opts} = Map.pop(opts, :username)
    {password, opts} = Map.pop(opts, :password)

    {socket_module, opts} = Map.pop(opts, :socket_module)
    {init_fn, opts} = Map.pop(opts, :init_fn)
    conn_opts = [:binary, active: false] ++ Enum.into(opts, [])

    {:ok, conn} = Socket.connect(socket_module, host, port, init_fn, conn_opts)
    client = %Client{conn: {socket_module, conn}}

    # todo: parse the server attributes and store them in the state
    imap_receive_raw(client)

    req = Request.login(username, password) |> Request.add_tag("EX_LGN")
    imap_send(client, req)

    client
  end

  def exec(%Client{tag_number: tag_number} = client, %Request{} = req) do
    resp = imap_send(client, %Request{req | tag: "EX#{tag_number}"})
    {%{client | tag_number: tag_number + 1}, resp}
  end

  defp imap_send(%{conn: conn}, req) do
    message = Request.raw(req)
    imap_send_raw(conn, message)
    imap_receive(conn, req)
  end

  defp imap_send_raw(conn, msg) do
    IO.puts "=== Sending ==="
    IO.puts msg
    IO.puts "==============="
    Socket.send(conn, msg)
  end

  defp imap_receive(conn, req) do
    msg = assemble_msg(conn, req.tag)
    # IO.inspect("R: #{msg}")
    %Response{request: req} |> parse_message(msg)
  end

  # assemble a complete message
  defp assemble_msg(conn, tag), do: assemble_msg(conn, tag, "")

  defp assemble_msg(conn, tag, msg) do
    {:ok, recv} = Socket.recv(conn)
    IO.puts "=== Receiving ==="
    IO.puts recv
    IO.puts "================="
    msg = msg <> recv
    if Regex.match?(~r/^.*#{tag} .*\r\n$/s, msg),
      do: msg,
      else: assemble_msg(conn, tag, msg)
  end

  defp parse_message(resp, ""), do: resp
  defp parse_message(resp, msg) do
    [part, other_parts] = get_msg_part(msg)
    {:ok, resp, other_parts} = Response.parse(resp, part, other_parts)
    if resp.partial, do: parse_message(resp, other_parts), else: resp
  end

  # get [message part, other message parts] that recognises {size}\r\n literals
  defp get_msg_part(msg), do: get_msg_part("", msg)
  defp get_msg_part(part, other_parts) do
    if other_parts =~ @literal do
      [_match | [size]] = Regex.run(@literal, other_parts)
      size = String.to_integer(size)
      [head, tail] = String.split(other_parts, @literal, parts: 2)
      # literal = for i <- 0..(size - 1), do: Enum.at(String.codepoints(tail), i)
      # Performace boost.  Large messages and attachments killed this and took > 2 minutes for a 40K attachment.
      cp=String.codepoints(tail)
      {literal, _post_literal_cp} = Enum.split(cp,size)
      literal = to_string(literal)
      {_, post_literal} = String.split_at(tail, String.length(literal))

      case post_literal do
        "\r\n" <> next -> [part <> head <> literal, next]
        _ -> get_msg_part(part <> head <> literal, post_literal)
      end
    else
      [h, t] = String.split(other_parts, "\r\n", parts: 2)
      [part <> h, t]
    end
  end

  defp imap_receive_raw(%{conn: conn}) do
    {:ok, msg} = Socket.recv(conn)
    msgs = String.split(msg, "\r\n", parts: 2)
    msgs = Enum.drop msgs, -1
    msgs
  end
end
