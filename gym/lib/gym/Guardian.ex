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
        clients = %{}
        {:ok, clients}
    end

    def handle_cast({:client_in, name}, clients) do
        client = Map.fetch(clients, name)
        clients = if client == :error do
                    {:ok, pid} = DynamicSupervisor.start_child(GYM.ClientSystem, GYM.Client)
                    Process.monitor(pid)
                    send(pid, name)
                    Map.put(clients, name, pid)
                  else
                    :ok = IO.puts("Client #{name} is already in the gym!")
                    clients
                  end
        {:noreply, clients}
    end

    def handle_info({:DOWN, _ref, :process, pid, reason}, clients) do
        client = Enum.find(clients, fn {_key, val} -> val == pid end)
        clients = if client != nil do
            {key, _value} = client
            Map.delete(clients, key)
        end
        if reason == :killed do
            GYM.Receptionist.checkout(GYM.Receptionist)
            :ok = IO.puts("Checked client #{inspect pid} out forcefully")
        end
        {:noreply, clients}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end

end