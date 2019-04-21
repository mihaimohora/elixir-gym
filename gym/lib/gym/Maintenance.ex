defmodule GYM.Maintenance do
    use Task

    def first_cleanup() do
        Task.async(&GYM.Maintenance.run/0)
    end

    def run() do
        :ok = IO.puts("Maintenance: starting to clean...")
        :timer.sleep(7000)
        :ok = IO.puts("Maintenance: cleaning done!")
    end

    def last_cleanup() do
        Task.async(&GYM.Maintenance.run/0)
    end
end