defmodule Chat.ProxyServerSupervisor do
# The reason of dynamic supervisor is that proxy server should be created on demand and listen to different ports. 
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: {:global, __MODULE__})
  end

  def start_worker(port) do
    DynamicSupervisor.start_child({:global, __MODULE__}, {Chat.ProxyServer, port})
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
