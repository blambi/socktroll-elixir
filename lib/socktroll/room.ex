defmodule Socktroll.Room do
  require Logger
  use GenServer

  alias Socktroll.User

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  def add_client(pid) do
    GenServer.call(__MODULE__, {:add, pid})
  end

  def remove_client() do
    GenServer.call(__MODULE__, :remove)
  end

  def rename_client(user) do
    GenServer.call(__MODULE__, {:rename, user})
  end

  def say(message) do
    GenServer.call(__MODULE__, {:say, message})
  end

  def action(message) do
    GenServer.call(__MODULE__, {:action, message})
  end

  def nicks() do
    {:ok, nicks} = GenServer.call(__MODULE__, :nicks)
    nicks
  end

  ## Callbacks

  def handle_call({:add, user}, _from, state) do
    Enum.each(state, fn({_pid, client}) -> # Send message to everyone
      send(client.pid, {:join, user.nick})
    end)
    Logger.info("#{user.nick} joined")
    {:reply, :ok, Map.put(state, user.pid, user)}
  end

  def handle_call(:remove, {pid, _ref}, state) do
    sender = state[pid]
    Enum.each(state, fn({_pid, client}) -> # Send message to everyone
      send(client.pid, {:part, sender.nick})
    end)
    Logger.info("#{sender.nick} left")
    {:reply, :ok, Map.delete(state, pid)}
  end

  def handle_call({:rename, user}, {pid, _ref}, state) do
    sender = state[pid]
    Enum.each(state, fn({_pid, client}) -> # Inform everyone else of the update
      unless client.pid == sender.pid do
        send(client.pid, {:rename, sender.nick, user.nick})
      end
    end)
    Logger.info("#{sender.nick} is now #{user.nick} ")
    {:reply, :ok, Map.put(state, user.pid, user)}
  end

  def handle_call({:say, message}, {pid, _ref}, state) do
    sender = state[pid]
    Enum.each(state, fn({_pid, user}) -> # Send message to everyone
      send(user.pid, {:say, sender.nick, message})
    end)
    Logger.info("<#{sender.nick}>: #{message}")
    {:reply, :ok, state}
  end

  def handle_call({:action, message}, {pid, _ref}, state) do
    sender = state[pid]
    Enum.each(state, fn({_pid, user}) -> # Send message to everyone
      send(user.pid, {:action, sender.nick, message})
    end)
    Logger.info("* #{sender.nick} #{message}")
    {:reply, :ok, state}
  end

  def handle_call(:nicks, _from, state) do
    nicks = Enum.map(state, fn({_pid, user}) ->
      user.nick
    end)
    {:reply, {:ok, nicks}, state}
  end
end
