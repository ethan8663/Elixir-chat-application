defmodule Chat.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        Chat.Server,
        {Registry, name: Chat.Registry, keys: :unique},
        Chat.ProxyServerSupervisor,
      ]

    # Stores group name(key) and count(value).
    :ets.new(:chat_group_count, [:named_table, :set, :public])

    # Stores every group-pid relationships. group name(key) and pid(value).
    :ets.new(:chat_groups, [:named_table, :bag, :public])
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
