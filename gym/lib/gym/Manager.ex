defmodule GYM.Manager do
    use Supervisor

    def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)
    end

    def init(:ok) do
        children = [
            {DynamicSupervisor, name: GYM.SubscriptionSystem, strategy: :one_for_one},
            {DynamicSupervisor, name: GYM.ClientSystem, strategy: :one_for_one},
            {GYM.Receptionist, name: GYM.Receptionist},
            {GYM.Guardian, name: GYM.Guardian}
        ]

        Supervisor.init(children, strategy: :one_for_one)
    end
end