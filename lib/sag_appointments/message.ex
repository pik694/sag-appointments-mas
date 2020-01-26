defmodule SagAppointments.Message do
  defstruct [:message, :content, :from, query: nil, query_id: nil]
end
