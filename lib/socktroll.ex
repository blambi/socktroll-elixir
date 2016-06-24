defmodule Socktroll do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: Socktroll.ClientSupervisor]]),
      worker(Task, [Socktroll.Server, :accept, [6000]]),
      worker(Socktroll.Room, [])
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end
