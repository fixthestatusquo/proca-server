defmodule ProcaWeb.Error do 
  defstruct [:code, :message, status_code: 200, context: []] 
end 
