defmodule GYM.Guardian do
    use GenServer

    @doc """
    Start the guardian
    """
    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    @doc """
    will be used to handle new clients
    """
    def let_client_in(server, name) do
        GenServer.cast(server, {:client_in, name})
    end

    def init(:ok) do
        {:ok, []}
    end

    def handle_cast({:client_in, name}, state) do
        {:ok, pid} = DynamicSupervisor.start_child(GYM.ClientSystem, GYM.Client)
        Process.monitor(pid)
        send(pid, name)
        {:noreply, state}
    end

    def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
        if reason == :killed do
            GYM.Receptionist.checkout(GYM.Receptionist)
            :ok = IO.puts("Checked client out forcefully")
        end
        {:noreply, state}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end

end