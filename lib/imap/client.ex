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
  ## Imap Client

  It's supposed to be used in a GenServer. It starts a linked Agent to hold to the client state.

  client = Client.new host: "imap.my.provider.com"
  Client.login(client, "my@provider.com", "my-unique-password")
  Client.list(client)
  Client.select(client, "INBOX")
  Client.fetch(client, "1:5")
  """

  @doc """
  Create a new IMAP client.

  Accepted options:

  - `:host` - The hostname of the IMAP server. (required)
  - `:port` - The port of the IMAP server. Default is 993.
  - `:socket_module` - The socket module to use. Default is `:ssl`.
  - `:init` - A function or a tuple `{module, function, args}` to be called after the connection is established.

  Connection options:

  For exmaple when using `:ssl`

  - `:ssl` - A list of options to pass to `:ssl.connect/4`. Default is `[:binary, active: false, cacertfile: CAStore.file_path()]`.
  """
  def new(opts) do
    opts = Enum.into(opts, %{})

    host = Map.fetch!(opts, :host)
    port = Map.get(opts, :port, 993)

    socket_module = Map.get(opts, :socket_module, :ssl)
    init = Map.get(opts, :init)

    conn_opts =
      case socket_module do
        :ssl ->
          [
            :binary
            | Keyword.merge(
                [active: false, cacertfile: CAStore.file_path()],
                Map.get(opts, :ssl, [])
              )
          ]

        other ->
          Map.get(opts, other, [])
      end

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

  @doc """
  Log the client in to the server with the given username and password.
  """
  def login(client, username, password) do
    with {:ok, _} <- Client.exec(client, Request.login(username, password)) do
      Agent.update(client, &Map.put(&1, :logged_in, true))
    end
  end

  @doc """
  Perform a LIST command on the server to get a list of mailboxes.
  """
  def list(client, reference \\ ~s|""|, mailbox \\ "%") do
    with true <- Agent.get(client, & &1.logged_in),
         {:ok, list} <- Client.exec(client, Request.list(reference, mailbox)) do
      for {scope, name, flags} <- list do
        %Imap.Mailbox{scope: scope, name: name, flags: flags}
      end
    end
    |> tap(fn mailboxes ->
      Agent.update(client, &Map.put(&1, :mailboxes, mailboxes))
    end)
  end

  @doc """
  Perform a SELECT command on a mailbox. Sets the currently selected mailbox in the client state.
  """
  def select(client, mailbox_name) do
    with true <- Agent.get(client, & &1.logged_in),
         {:ok, resp} <- Client.exec(client, Request.select(mailbox_name)) do
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

      mailbox =
        Agent.get(
          client,
          &get_in(&1, [
            Access.key!(:mailboxes),
            Access.find(fn %{name: name} -> name == mailbox_name end)
          ])
        )

      Agent.update(client, &Map.put(&1, :selected_mailbox, mailbox))

      mailbox
    end
  end

  @doc """
  Execute an IMAP command with the client.
  """
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
    Logger.debug(">>> #{message}")
    Socket.send(conn, message)
  end

  defp imap_receive(%{conn: conn}, req) do
    assemble_msg(conn, req.tag)
  end

  defp assemble_msg(conn, tag) do
    {:ok, message} = Socket.recv(conn)

    Logger.debug("<<<\n#{message}")

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
