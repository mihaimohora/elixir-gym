defmodule GYM.Client do
    use Task, restart: :transient

    def start_link(_opts) do
        Task.start_link(&GYM.Client.get_client_to_instructor/0)
    end

    def get_client_to_instructor() do
        IO.puts("#{inspect self()}" <> ": Send name!")
        receive do
            name -> IO.puts(name)
            GYM.Receptionist.checkin(GYM.Receptionist, name)
            :timer.sleep(20000)
            GYM.Receptionist.checkout(GYM.Receptionist)
        end
        
    end
end