defmodule Socktroll.Server do
  require Logger

  alias Socktroll.Room
  alias Socktroll.Protocol
  alias Socktroll.User

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Socktroll.ClientSupervisor, fn ->
      user = %User{
        pid: self(),
        socket: client
      }
      serve(user)
    end)
    :gen_tcp.controlling_process(client, pid)

    loop_acceptor(socket)
  end

  defp serve(user) do
    read_mbox(user.socket)
    case read_line(user.socket) do
      :error ->
        Logger.info("Lost a client")
        if user.nick do
          Socktroll.Room.remove_client()
        end
        :error
      :timeout ->
        serve(user)
      data ->
        #write_line(data, socket)
        user =
          case Protocol.handle(user, data) do
            {:reply, user, message} ->
              write_line(message, user.socket)
              user
            {:noreply, user} ->
              user
            :exit ->
              if user.nick do
                Socktroll.Room.remove_client()
              end
              nil # ensure we don't have a user (and there by disconnect?)
          end

        if user do
          serve(user)
        end
    end
  end

  defp read_mbox(socket) do
    receive do
      {:say, sender, message} ->
        write_line("msg " <> sender <> " " <> message, socket)
      {:join, who} ->
        write_line("+ " <> who, socket)
      {:part, who} ->
        write_line("- " <> who, socket)
      {:rename, from, to} ->
        write_line("rename " <> from <> " " <> to, socket)
      {:action, who, message} ->
        write_line("action " <> who <> " " <> message, socket)
      _ ->
        Logger.warn("Strange messages was recived internaly!")
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
