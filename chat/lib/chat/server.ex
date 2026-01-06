defmodule Chat.Server do
  #   # The reason behind dynamic supervisor is that if worker send too large input or suspicious, we can immediately kill the process and restart it. At the moment, server can not kill the worker process. 
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_worker(socket) do
    DynamicSupervisor.start_child(__MODULE__, {Chat.Proxy, socket})
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
