defmodule Imap.Client do
  alias Imap.{Parser, Request, Response, Socket, Client}

  require Logger

  defstruct [
    :conn,
    :capability,
    selected_mailbox: nil,
    mailboxes: [],
    logged_in: false,
    tag_number: 1
  ]

  @moduledoc """
  Imap Client GenServer
  """

  def new(opts) do
    opts = Enum.into(opts, %{})

    {host, opts} = Map.pop(opts, :host)
    {port, opts} = Map.pop(opts, :port, 993)

    {socket_module, opts} = Map.pop(opts, :socket_module, :ssl)
    {init, opts} = Map.pop(opts, :init)

    conn_opts =
      [:binary, active: false, cacertfile: CAStore.file_path()] ++ Enum.into(opts, [])

    :ok =
      case init do
        nil ->
          :ok

        f when is_function(f) ->
          f.()

        {m, f, a} when is_atom(m) and is_atom(f) and is_list(a) ->
          apply(m, f, a)
      end

    {:ok, conn} = Socket.connect(socket_module, to_charlist(host), port, conn_opts)
    conn = {socket_module, conn}

    {:ok, agent} =
      Agent.start_link(fn ->
        %Client{conn: conn, capability: imap_receive_raw(conn)}
      end)

    agent
  end

  def login(client, username, password) do
    with {:ok, _} <- Client.exec(client, Request.login(username, password)) do
      Agent.update(client, &Map.put(&1, :logged_in, true))
    end
  end

  def list(client) do
    with true <- Agent.get(client, & &1.logged_in),
         {:ok, list} <- Client.exec(client, Request.list()) do
      for {scope, name, flags} <- list do
        %Imap.Mailbox{scope: scope, name: name, flags: flags}
      end
    end
    |> tap(fn mailboxes ->
      Agent.update(client, &Map.put(&1, :mailboxes, mailboxes))
    end)
  end

  def select(client, mailbox_name) do
    with true <- Agent.get(client, & &1.logged_in),
         {:ok, resp} <- Client.exec(client, Request.select(mailbox_name)) do
      Agent.update(client, &Map.put(&1, :selected_mailbox, mailbox_name))

      mailbox_status =
        Enum.reduce(resp, %{}, fn
          {"EXISTS", n}, acc -> Map.put(acc, :exists, n)
          {"RECENT", n}, acc -> Map.put(acc, :recent, n)
          _, acc -> acc
        end)

      Agent.update(client, fn state ->
        update_in(
          state,
          [Access.key!(:mailboxes), Access.find(fn %{name: name} -> name == mailbox_name end)],
          &Map.merge(&1, mailbox_status)
        )
      end)

      Agent.get(
        client,
        &get_in(&1, [
          Access.key!(:mailboxes),
          Access.find(fn %{name: name} -> name == mailbox_name end)
        ])
      )
    end
  end

  def exec(client_agent, %Request{} = req) do
    client =
      Agent.get_and_update(
        client_agent,
        &{&1, %{&1 | tag_number: &1.tag_number + 1}}
      )

    req = %{req | tag: "EX#{client.tag_number}"}

    imap_send(client, req)

    imap_receive(client, req)
    |> Parser.response()
    |> Response.extract()
  end

  defp imap_send(%{conn: conn}, req) do
    message = Request.serialize(req)

    imap_send_raw(conn, message)
  end

  defp imap_send_raw(conn, message) do
    Logger.debug("=== Sending ===")
    Logger.debug(message)
    Logger.debug("===============")
    Socket.send(conn, message)
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
    {:ok, message} = Socket.recv(conn)
    message
  end
end
