
defmodule ProcaWeb.MailboxPlug do
  import Plug.Conn

  alias Proca.Service.Preview.OrgStorage

  def init(opts), do: opts

  def call(conn, _opts) do
    org_name = conn.params["org_name"]
    emails = OrgStorage.get(org_name)

    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, render(org_name, emails))
  end

  defp render(org_name, emails) do
    """
    <h1>Mailbox for #{org_name}</h1>
    <ul>
      #{for email <- emails do
        """
        <li>
          <p><b>To:</b> #{inspect(email.to)}</p>
          <p><b>Subject:</b> #{email.subject}</p>
          <p><b>Body:</b></p>
          <pre>#{email.text_body}</pre>
          <hr>
        </li>
        """
      end}
    </ul>
    """
  end
end
