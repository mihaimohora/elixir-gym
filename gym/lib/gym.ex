defmodule GYM do
  use Application
  
  def start(_type, _args) do
    GYM.Manager.start_link(name: GYM.Manager)
  end

  def prep_stop(_state) do
    task = GYM.Maintenance.last_cleanup()
    Task.await(task, 15000)
  end
end
