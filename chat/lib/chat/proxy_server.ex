defmodule Chat.ProxyServer do
  use GenServer

  def start_link(port \\ 6666) do
    GenServer.start_link(__MODULE__, port, name: {:global, {__MODULE__, port}})
  end

  @impl true
  def init(port) do
    opts = [:binary, active: :once, packet: :line, reuseaddr: true]
    case :gen_tcp.listen(port, opts) do
      {:ok, listen_socket} ->
        send(self(), :accept)
        {:ok, listen_socket}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_info(:accept, listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        {:ok, pid} = Chat.Server.start_worker(socket)
        :gen_tcp.controlling_process(socket, pid)
        send(self(), :accept)
        {:noreply, listen_socket}
      {:error, reason} ->
        {:stop, reason, listen_socket}
    end
  end
end
