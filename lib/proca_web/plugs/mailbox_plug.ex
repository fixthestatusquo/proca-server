
defmodule ProcaWeb.MailboxPlug do
  import Plug.Conn

  alias Proca.Service.Preview.OrgStorage

  def init(opts), do: opts

  def call(conn, _opts) do
    email_id = conn.params["message_id"]
    email = OrgStorage.get(email_id)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, render(email))
  end

  defp render(email) do
    """
    <h1>Mailbox for #{email.assigns.target.name}</h1>
    <ul>
      <li>
        <p><b>To:</b> #{inspect(email.to)}</p>
        <p><b>Subject:</b> #{email.subject}</p>
        <p><b>Body:</b></p>
        <pre>#{email.text_body}</pre>
        <hr>
      </li>
    </ul>
    """
  end
end
