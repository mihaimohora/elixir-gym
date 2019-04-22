defmodule GYM.Subscription do
  use Agent, restart: :temporary

  @doc """
  Creates a new subscription.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> _entrances = 10 end)
  end

  @doc """
  Get the number of remaining entrances.
  """
  def get_entrances(subscription) do
    Agent.get(subscription, fn entrances -> entrances end)
  end

  @doc """
  Decrease the number of remaining entrances.
  """
  def decrease_entrances(subscription) do
    Agent.update(subscription, fn
      entrances when entrances > 0 -> entrances - 1
      _entrances -> 0
    end)

    get_entrances(subscription)
  end

@doc """
renew the subscription:  set the nr of available entrances back to 10
"""
  def renew_subscription(subscription) do
    Agent.update(subscription, fn _entrances -> 10 end)
  end
end
