defmodule GYM.Instructor do
  use Agent, restart: :temporary

  @doc """
  Create a new instructor
  """
  def start_link(_opts) do
    Agent.start_link(fn -> _students = 0 end)
  end

  @doc """
  Increase the number of active students
  """
  def receive_student(instructor) do
    Agent.update(instructor, fn
      students when students < 4 -> students + 1
      _students -> 4
    end)
    ##get_active_students(instructor)
  end

  @doc """
  Decrease the number of active students
  """
  def release_student(instructor) do
    Agent.update(instructor, fn
      students when students > 0 -> students - 1
      _students -> 0
    end)
    ##get_active_students(instructor)
  end

  def get_active_students(instructor) do
      Agent.get(instructor, fn students -> students end)
  end
end
