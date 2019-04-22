defmodule GYM.Client do
    use Task, restart: :transient

    def start_link(_opts) do
        Task.start_link(&GYM.Client.get_client_to_instructor/0)
    end

    def get_client_to_instructor() do
        IO.puts("#{inspect self()}" <> ": Send name!")
        receive do
            name -> IO.puts("#{inspect self()} got this name: " <> name)
            response = GYM.Receptionist.checkin(GYM.Receptionist, name)
            if response == :checkedIn do
        
                :timer.sleep(20000)
                GYM.Receptionist.checkout(GYM.Receptionist, name)
            else
                IO.puts("#{name}: I will come back later!")
            end
        end
        
    end
end