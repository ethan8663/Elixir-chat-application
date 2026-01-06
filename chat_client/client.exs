defmodule Chat.Client do
  def main(args) do
    {host, port} =
      case args do
        [h, p] -> {to_charlist(h), String.to_integer(p)}
        [h] -> {to_charlist(h), 6666}
        _ -> {~c"localhost", 6666}
      end

    case :gen_tcp.connect(host, port, [:binary, active: false]) do
      {:ok, socket} ->
        IO.puts("connected to #{host}:#{port}")

        # print whatever the server sends
        spawn(fn -> recv_loop(socket) end)

        # read what the user types and send it
        send_loop(socket)

      {:error, reason} ->
        IO.puts("connect failed: #{inspect(reason)}")
    end
  end

  defp recv_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.puts(data)
        recv_loop(socket)

      {:error, :closed} ->
        IO.puts("connection closed")
    end
  end

  defp send_loop(socket) do
    case IO.gets("") do
      nil ->
        :gen_tcp.close(socket)
        :ok

      line ->
        :gen_tcp.send(socket, line)
        send_loop(socket)
    end
  end
end

Chat.Client.main(System.argv())
