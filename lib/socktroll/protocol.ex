defmodule Socktroll.Protocol do
  require Logger
  alias Socktroll.Room
  alias Socktroll.User

  def handle(user = %User{nick: nil}, "nick " <> nick) do
    if nick in Room.nicks() do
      # taken
      {:reply, user, "no taken"}
    else
      user = %{user | nick: nick}
      Room.add_client(user)
      {:reply, user, "ok " <> user.nick}
    end
  end

  def handle(user, "nick " <> nick) do
    # Nick change
    if nick in Room.nicks() do
      # taken
      {:reply, user, "no taken"}
    else
      user = %{user | nick: nick}
      Room.rename_client(user)
      {:reply, user, "ok " <> user.nick}
    end
  end

  def handle(user = %User{nick: nil}, "msg " <> nick) do
    {:reply, user, "msg server You must choose a nick first"}
  end

  def handle(user, "msg " <> message) do
    Room.say(message)
    {:noreply, user}
  end

  def handle(user = %User{nick: nil}, "action " <> nick) do
    {:reply, user, "msg server You must choose a nick first"}
  end

  def handle(user, "action " <> message) do
    Room.action(message)
    {:noreply, user}
  end

  def handle(user, "names") do
    {:reply, user, "names " <> build_names(Room.nicks())}
  end

  def handle(user, "quit") do
    :exit
  end

  def handle(user, message) do
    Logger.info("Unknown message '#{message}' recived")
    {:reply, user, "illegal command"}
  end

  defp build_names([nick | names]) do
    build_names(names, nick)
  end

  defp build_names([nick | names], string) do
    build_names(names, string <> "," <> nick)
  end

  defp build_names([], string) do
    string
  end
end
