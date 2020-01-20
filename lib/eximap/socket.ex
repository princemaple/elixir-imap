defmodule Eximap.Socket do
  @moduledoc """
  A socket module that abstracts away the type of the connection it has with a server.
  """

  @doc false
  def connect(socket_module, host, port, init_fn, opts) do
    init_fn.()
    socket_module.connect(host, port, opts)
  end

  @doc false
  def setopts({socket_module, conn}, opts) do
    socket_module.setopts(conn, opts)
  end

  @doc false
  def send({socket_module, conn}, msg) do
    socket_module.send(conn, msg)
  end

  @doc false
  def recv({socket_module, conn}) do
    socket_module.recv(conn, 0)
  end
end
