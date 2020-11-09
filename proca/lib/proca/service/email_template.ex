defmodule Proca.Service.EmailTemplate do
  @moduledoc """
  Models an email tempalate to be rendered into a thank you email, etc.
  """
  defstruct name: "", subject: "", html: "", text: "", ref: ""
end
