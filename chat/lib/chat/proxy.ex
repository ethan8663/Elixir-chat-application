defmodule Chat.Proxy do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  @impl true
  def init(socket) do
    {:ok, {"0", socket}} # "0" is default nickname and needs to be changed
  end

  @impl true
  def handle_info({:tcp, socket, data}, {nickname, socket}) do
    :inet.setopts(socket, active: :once)

    data = String.trim(data)
    lower_data = String.downcase(data)

    cond do
      String.starts_with?(lower_data, "/nck") ->
        parts = String.split(data, " ")
        {nickname, msg} = if length(parts) >= 2 do
          new_nickname = Enum.at(parts, 1)
          if validate_nickname?(new_nickname) do
            if nickname == "0" do # Nickname have not set
              case Registry.register(Chat.Registry, new_nickname, nil) do
                {:ok, _} ->
                  {new_nickname, "Success: the #{new_nickname} is registered\n"}
                {:error, {:already_registered, _}} ->
                  {nickname, "Error: the #{new_nickname} is already registered\n"}
              end
            else # User has nickname
              case Registry.lookup(Chat.Registry, new_nickname) do
                [] -> # new nickname is not duplicate
                  Registry.unregister(Chat.Registry, nickname)
                  Registry.register(Chat.Registry, new_nickname, nil)
                  {new_nickname, "Success: nickname changed from #{nickname} to #{new_nickname}\n"}
                _ ->
                  {nickname, "Error: the name #{new_nickname} is already registered\n"}
              end
            end
          else
            {nickname, "Error: nickname has to be valid format\n"}
          end
        else
          {nickname, "Error: /NCK command must have one argument\n"}
        end

      :gen_tcp.send(socket, msg)
      {:noreply, {nickname, socket}}

      String.starts_with?(lower_data, "/lst") ->
        nicknames = Registry.select(Chat.Registry, [
          {{:"$1", :_, :_}, [], [:"$1"]}
        ])

        nicknames =
          case nicknames do
            [] -> "No users"
            _ -> Enum.join(nicknames, ", ")
          end

      :gen_tcp.send(socket, nicknames <> "\n")
      {:noreply, {nickname, socket}}

      String.starts_with?(lower_data, "/msg") ->
        parts = String.split(data, " ")
        if nickname != "0" do # user has set nickname
          if length(parts) >= 3 do
            target = Enum.at(parts, 1)
            msg = parts
              |> Enum.drop(2)
              |> Enum.join(" ")

            if String.starts_with?(target, "#") do # group message
              group_name = String.trim_leading(target, "#")
              case :ets.lookup(:chat_group_count, group_name) do
                [] ->
                  :gen_tcp.send(socket, "Error: no such group as #{group_name}\n")
                [{^group_name, _}] ->
                  members = :ets.lookup(:chat_groups, group_name)
                  Enum.each(members, fn {_, pid} ->
                    send(pid, {:msg, msg}) end)
                  :gen_tcp.send(socket, "Success: message sent\n")
              end
            else # message to user/users
              recipients = String.split(target, ",")
              Enum.each(recipients, fn name ->
                case Registry.lookup(Chat.Registry, name) do
                  [{pid, _}] ->
                    send(pid, {:msg, msg})
                  [] ->
                    :gen_tcp.send(socket, "Error: #{name} not found\n")
                end
              end)
            end
        else
          :gen_tcp.send(socket, "Error: /MSG must have 2 arguments\n")
        end
        else
          :gen_tcp.send(socket, "Error: must set nickname first")
        end

        {:noreply, {nickname, socket}}

        String.starts_with?(lower_data, "/grp") ->
          if nickname != "0" do # nickname is not default
            parts = String.split(data, " ")
            if length(parts) >= 3 do
              group = Enum.at(parts, 1)
              members = String.split(Enum.at(parts, 2), ",")

              if validate_group_name?(group) do
                group_name = String.trim_leading(group, "#")
                case :ets.lookup(:chat_group_count, group_name) do
                  [] -> # there is no group
                    :ets.insert(:chat_group_count, {group_name, length(members)})

                    Enum.each(members, fn name ->
                      case Registry.lookup(Chat.Registry, name) do
                        [{pid, _}] ->
                          :ets.insert(:chat_groups, {group_name, pid})
                        [] ->
                          :gen_tcp.send(socket, "Error: #{name} is not registered\n")
                      end
                    end)

                    :gen_tcp.send(socket, "Success: group #{group_name} created.")

                  [{_, count}] -> # There is a group
                    :ets.insert(:chat_group_count, {group_name, count + length(members)})
                    Enum.each(members, fn name ->
                      case Registry.lookup(Chat.Registry, name) do
                        [{pid, _}] ->
                          :ets.insert(:chat_groups, {group_name, pid})
                        [] ->
                          :gen_tcp.send(socket, "Error: #{name} is not registered\n")
                      end
                        end)
                    :gen_tcp.send(socket, "Success: group #{group_name} updated\n")
                end
              else
                :gen_tcp.send(socket, "Error: group name should start with # and in proper format\n")
              end
            else
              :gen_tcp.send(socket, "Error: /GRP must have 2 arguments\n")
            end
          else
            :gen_tcp.send(socket, "Error: must set nickname first")
          end

          {:noreply, {nickname, socket}}

        true ->
          :gen_tcp.send(socket, "Error: wrong command\n")
          {:noreply, {nickname, socket}}
    end

  end

  @impl true
  def handle_info({:tcp_closed, socket}, {nickname, socket}) do
    :gen_tcp.close(socket)

    pid = self()

    IO.puts("connection closed: #{inspect pid}")
    # Find all groups that pid belonged
    groups =
      :ets.select(:chat_groups, [
        {{:"$1", pid}, [], [:"$1"]}
      ])

    Enum.each(groups, fn group ->
      case :ets.lookup(:chat_group_count, group) do
        [{^group, 1}] ->
          # last member -> remove group entry
          :ets.delete(:chat_group_count, group)
          IO.puts("group: #{inspect group} is deleted")

        [{^group, n}] ->
          :ets.insert(:chat_group_count, {group, n - 1})
      end
    end)

    # Delete all rows for this pid
    :ets.select_delete(:chat_groups, [
      {{:"$1", pid}, [], [true]}
    ])

    {:stop, :normal, {nickname, socket}}
  end

  @impl true
  def handle_info({:msg, msg}, {nickname, socket}) do
    :gen_tcp.send(socket, msg)
    {:noreply, {nickname, socket}}
  end

  defp validate_nickname?(nickname) do
    if String.length(nickname) > 10 do
      false
    else
      case String.at(nickname, 0) do
        <<c>> when c in ?A..?Z or c in ?a..?z ->
          rest = String.slice(nickname, 1..-1//1)

          Enum.all?(String.to_charlist(rest), fn ch ->
            (ch in ?A..?Z) or
              (ch in ?a..?z) or
              (ch in ?0..?9) or
              ch == ?_
          end)

        _ ->
          false
      end
    end
  end

  defp validate_group_name?(group_name) do
    if String.length(group_name) > 11 do
      false
    else
      case String.at(group_name, 0) do
        "#" ->
          first = String.at(group_name, 1)

          case first do
            <<c>> when c in ?A..?Z or c in ?a..?z ->
              rest = String.slice(group_name, 2..-1//1)

              Enum.all?(String.to_charlist(rest), fn ch ->
                (ch in ?A..?Z) or
                  (ch in ?a..?z) or
                  (ch in ?0..?9) or
                  ch == ?_
              end)

            _ ->
              false
          end

        _ ->
          false
      end
    end
  end
end
