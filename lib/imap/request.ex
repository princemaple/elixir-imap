defmodule Imap.Request do
  @moduledoc """

  """
  defstruct tag: "TAG", command: nil, params: []

  alias __MODULE__

  def serialize(%Request{tag: tag, command: command, params: params}) do
    params =
      params
      |> List.flatten()
      |> case do
        [] -> nil
        _ -> Enum.join(params, " ")
      end

    [tag, command, params]
    |> Enum.filter(& &1)
    |> Enum.join(" ")
    |> Kernel.<>("\r\n")
  end

  @ops [
    noop: [],
    capability: [],
    authenticate: [:mechanism],
    login: [:username, :password],
    logout: [],
    list: [reference: ~s|""|, mailbox: "%"],
    lsub: [reference: ~s|""|, mailbox: ~s|""|],
    select: [:name],
    subscribe: [:name],
    unsubscribe: [:name],
    examine: [:name],
    create: [:name],
    delete: [:name],
    status: [:name],
    append: [:name, :opts],
    rename: [:name, :new_name],
    check: [],
    starttls: [],
    close: [],
    expunge: [],
    search: [:flags],
    fetch: [:sequence, :flags],
    store: [:sequence, :item, :value],
    copy: [:sequence, :mailbox],
    uid: [:params]
  ]

  for {op, params} <- @ops do
    command = op |> to_string |> String.upcase()

    parameters =
      Enum.map(params, fn
        arg when is_atom(arg) -> Macro.var(arg, Elixir)
        {arg, default} -> quote(do: unquote(Macro.var(arg, Elixir)) \\ unquote(default))
      end)

    items =
      Enum.map(params, fn
        arg when is_atom(arg) -> Macro.var(arg, Elixir)
        {arg, _default} -> Macro.var(arg, Elixir)
      end)

    def unquote(op)(unquote_splicing(parameters)) do
      %Request{command: unquote(command), params: [unquote_splicing(items)]}
    end
  end
end
