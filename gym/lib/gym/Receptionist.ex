defmodule GYM.Receptionist do
    use GenServer

    @doc """
    Start the receptionist
    """
    def start_link(opts) do
        GenServer.start_link(__MODULE__, :ok, opts)
    end

    @doc """
    lookup for a subscription to check if it exists
    returns {:ok, pid} if found, and :error if not
    """
    def lookup_subscription(server, client) do
        GenServer.call(server, {:lookupSubscription, client})
    end

    @doc """
    create subscription for the given client
    """
    def create_subscription(server, client) do
        GenServer.call(server, {:createSubscription, client})
    end

    @doc """
    Get the list of instructors
    """
    def get_instructors(server) do
        GenServer.call(server, :getInstructors)
    end

    @doc """
    checks a client in by a given name
    """
    def checkin(server, name) do
        result = lookup_subscription(server, name)
        if result != :error do
            {:ok, pid} = result
            :ok = IO.puts("Found #{name}'s subscription!")
            available_entrances = GYM.Subscription.get_entrances(pid)
            
            if available_entrances <= 0 do
                :ok = IO.puts("#{name} has no entrances left! We will renew the subscription!")
                GYM.Subscription.renew_subscription(pid)
                GYM.Subscription.decrease_entrances(pid)
            end
        else
            :ok = IO.puts("#{name} has no subscription! We will create one using this name!")
            create_subscription(server, name)
        end

        {:ok, pid} = lookup_subscription(server, name)
        first_available_instructor = get_first_available_instructor(server)
        result = if first_available_instructor != nil do
            GYM.Subscription.decrease_entrances(pid)
            {key, value} = first_available_instructor
            :ok = IO.puts("#{name}, we found you an available instructor: #{key}")
            GYM.Instructor.receive_student(value)
            :checkedIn
        else
            :ok = IO.puts("#{name}, there is no instructor available, please come back later!!")
            :error
        end
        result
    end

    @doc """
    checks a client out and releases an instructor - the first one that has active students
    """
    def checkout(server, name \\ "default") do
        if name != "default" do
            IO.puts("#{name} is leaving")
        end
        first_busy_instructor = get_first_busy_instructor(server)
        if first_busy_instructor != nil do
            {key, value} = first_busy_instructor
            :ok = IO.puts("Freeing " <> "#{key}")
            GYM.Instructor.release_student(value)

        end
    end

    defp get_first_busy_instructor(server) do
        instructors = get_instructors(server)
        instructor = Enum.find(instructors, fn {_key, value} -> GYM.Instructor.get_active_students(value) > 0 end) 
        instructor
    end

    defp get_first_available_instructor(server) do
        instructors = get_instructors(server)
        instructor = Enum.find(instructors, fn {_key, value} -> GYM.Instructor.get_active_students(value) < 1 end)
        instructor
    end

    ## Server callbacks
    def init(:ok) do
        clients = %{}
        instructors = %{}
        
        instructors = create_instructor(instructors, 4)    

        task = GYM.Maintenance.first_cleanup()
        Task.await(task, 10000)

        {:ok, {clients, instructors}}
    end

    defp create_instructor(instructors, total) when total <= 1 do
        {:ok, pid} = DynamicSupervisor.start_child(GYM.SubscriptionSystem, GYM.Instructor)
        Process.monitor(pid)
        name = "instructor" <> "#{total}"
        instructors = Map.put(instructors, name, pid)
        instructors
    end

    defp create_instructor(instructors, total) do
        {:ok, pid} = DynamicSupervisor.start_child(GYM.SubscriptionSystem, GYM.Instructor)
        Process.monitor(pid)
        name = "instructor" <> "#{total}"
        instructors = Map.put(instructors, name, pid)
        create_instructor(instructors, total - 1)
    end

    def handle_call({:lookupSubscription, client}, _from, state) do
        {clients, _} = state
        {:reply, Map.fetch(clients, client), state}
    end

    def handle_call({:createSubscription, client}, _from, state) do
        {clients, instructors} = state
        if Map.has_key?(clients, client) do
            {:reply, :alreadyExists, state}
        else
            {:ok, subscription} = DynamicSupervisor.start_child(GYM.SubscriptionSystem, GYM.Subscription)
            Process.monitor(subscription)
            result = Map.put(clients, client, subscription)
            {:reply, result, {result, instructors}}
        end
    end

    def handle_call(:getInstructors, _from, state) do
        {_, instructors} = state
        {:reply, instructors, state}
    end

    def handle_info({:DOWN, _ref, :process, pid, _reason}, {clients, instructors}) do
        agent = Enum.find(clients, fn {_key, val} -> val == pid end)
        clients = if agent != nil do
            {key, _value} = agent
            Map.delete(clients, key)
        end

        agent = Enum.find(instructors, fn {_key, val} -> val == pid end)
        instructors = if agent != nil do
                {key, _value} = agent
                Map.delete(instructors, key)
        end

        {:noreply, {clients, instructors}}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end    
end