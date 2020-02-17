defmodule Imap.Client do
  alias Imap.Parser
  alias Imap.Request
  alias Imap.Response
  alias Imap.Socket

  alias __MODULE__

  require Logger

  defstruct [:conn, :capability, tag_number: 1]

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
    conn = {socket_module, conn}
    client = %Client{conn: conn, capability: imap_receive_raw(conn)}

    exec(client, Request.login(username, password))
  end

  def exec(%Client{tag_number: tag_number} = client, %Request{} = req) do
    req = %{req | tag: "EX#{tag_number}"}

    imap_send(client, req)

    resp =
      imap_receive(client, req)
      |> Parser.response()
      # |> Response.parse()

    {%{client | tag_number: tag_number + 1}, resp}
  end

  defp imap_send(%{conn: conn}, req) do
    message = Request.raw(req)

    imap_send_raw(conn, message)
  end

  defp imap_send_raw(conn, msg) do
    Logger.debug("=== Sending ===")
    Logger.debug(msg)
    Logger.debug("===============")
    Socket.send(conn, msg)
  end

  defp imap_receive(%{conn: conn}, req) do
    assemble_msg(conn, req.tag)
  end

  defp assemble_msg(conn, tag) do
    {:ok, message} = Socket.recv(conn)

    Logger.debug("=== Receiving ===")
    Logger.debug(message)
    Logger.debug("=================")

    if Regex.match?(~r/^.*#{tag} .*\r\n$/s, message) do
      message
    else
      message <> assemble_msg(conn, tag)
    end
  end

  defp imap_receive_raw(conn) do
    {:ok, msg} = Socket.recv(conn)
    msg
  end
end
