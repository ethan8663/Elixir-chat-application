defmodule Chat.ProxyServerSupervisor do
  def start_proxy_server(port \\ 6666) do
    DynamicSupervisor.start_child({:global, __MODULE__},
      %{
        id: {Chat.ProxyServer, port},
        start: {Chat.ProxyServer, :start_link, [port]}
      })
  end
end
