defmodule Socktroll.Server do
  require Logger

  alias Socktroll.Room
  
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Socktroll.ClientSupervisor, fn ->
      serve(client)
    end)
    :gen_tcp.controlling_process(client, pid)
    Room.add_client(pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    read_mbox(socket)
    case read_line(socket) do
      :error ->
        Logger.info("Lost a client")
        Socktroll.Room.remove_client()
        :error
      :timeout ->
        serve(socket)
      data ->
        #write_line(data, socket)
        Room.say(data)
        serve(socket)
    end
  end

  defp read_mbox(socket) do
    receive do
      {:say, message} ->
        write_line(message, socket)
      _ ->
        Logger.warn("Strange messages to a client from us!")
    after
      10 ->
        nil
    end
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0, 10) do
      {:ok, data} ->
        String.trim_trailing(data)
      {:error, :closed} ->
        :error
      {:error, :timeout} ->
        :timeout
    end
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line <> "\n")
  end
end
