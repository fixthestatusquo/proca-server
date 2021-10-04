defmodule ProcaWeb.LayoutView do
  use ProcaWeb, :view

  def gravatar_url(nil) do 
    "//gravatar.com/avatar/default"
  end

  def gravatar_url(user) do 
    h = :crypto.hash(:md5, user.email) 
    |> Base.encode16() 
    |> String.downcase()
    "//gravatar.com/avatar/" <> h
  end
end
