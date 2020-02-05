defmodule Imap.Client do
  alias Imap.Request
  alias Imap.Socket

  alias __MODULE__

  defstruct [:conn, tag_number: 1]

  @moduledoc """
  Imap Client GenServer
  """

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
    IO.inspect imap_receive_raw(client)

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
    message = assemble_msg(conn, req.tag)
    Task.start(fn ->
      message
      |> Imap.Parser.response()
      |> IO.inspect
    end)
    message
    # %Response{request: req} |> parse_message(msg)
  end

  defp assemble_msg(conn, tag) do
    {:ok, message} = Socket.recv(conn)

    IO.puts "=== Receiving ==="
    IO.puts message
    IO.puts "================="

    if Regex.match?(~r/^.*#{tag} .*\r\n$/s, message) do
      message
    else
      message <> assemble_msg(conn, tag)
    end
  end

  defp imap_receive_raw(%{conn: conn}) do
    {:ok, msg} = Socket.recv(conn)
    msg
  end
end
