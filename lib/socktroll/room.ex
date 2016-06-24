defmodule Socktroll.Room do
  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
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

  def say(message) do
    GenServer.call(__MODULE__, {:say, message})
  end

  ## Callbacks

  def handle_call({:add, pid}, _from, state) do
    Logger.info("Added a client")
    state = 
      [pid | state]
      |> Enum.uniq()
    
    {:reply, :ok, state}
  end

  def handle_call(:remove, {pid, _ref}, state) do
    Logger.info("Removed a client")
    state = Enum.reject(state, fn(x) ->
      x == pid
    end)

    {:reply, :ok, state}
  end

  def handle_call({:say, message}, {pid, _ref}, state) do
    Logger.info("Someone said: #{message}")
    # Send message to everyone
    Enum.each(state, fn(client) ->
      unless client == pid do
        send(client, {:say, message})
      end
    end)
    {:reply, :ok, state}
  end
end
