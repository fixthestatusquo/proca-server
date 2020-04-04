defmodule ProcaWeb.EncryptionController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca
  alias Proca.Org
  alias Proca.PublicKey
  alias Proca.Repo
  alias Ecto.Changeset
  import Ecto.Query

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "encryption.html", assigns)
  end


  def handle_event("pk_save", %{"public_key" => pk}, socket) do
    IO.inspect(pk, label: "handle event save")
    org = socket.assigns.org
    new_pk = case PublicKey.changeset(%PublicKey{}, pk) do
               %{valid?: true,
                 changes: %{
                   name: _name,
                   public: _public
                 }
               } = ch ->
                 with {:ok, ch2} <- changeset_from_base64(ch),
                      {:ok, _saved_pk} <- save_as_only_active(ch2, socket)
                   do
                   org = Org.get_by_id(org.id, [:public_keys])

                   socket
                   |> assign(:org, org)
                   |> put_flash(:info, "Key saved")

                   {:ok,  PublicKey.changeset(%PublicKey{}, %{})}

                   else
                     {:error, ch} -> ch
                 end

               x = %{valid?: true, changes: %{name: name}} ->
                 IO.inspect(x, label: "gen key")
                 PublicKey.build_for(org, name)
                 |> changeset_to_base64

               ch ->
                 IO.puts "meh"
                 ch
    end
    |> Map.put(:action, :insert)

    {:noreply,
     socket
     |> assign(:new_pk, new_pk)
    }
  end

  def save_as_only_active(ch, socket) do
    org_id = socket.assigns[:staffer].org_id
    case Repo.insert(ch) do
      {:ok, saved} ->
        IO.inspect(saved, label: "saved pk")
        now = DateTime.utc_now()
        Repo.update_all(
          from(pk in PublicKey, where: pk.org_id == ^org_id and pk.id != ^saved.id),
          [update: [set: [expired_at: now]]]
        )
        {:ok, saved}
      {:error, ch} -> ch
    end
  end


  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    org = socket.assigns[:staffer].org_id
    |> Org.get_by_id([:public_keys])

    {:ok,
     socket
     |> assign(:org, org)
     |> assign(:new_pk, PublicKey.changeset(%PublicKey{}, %{}))
    }
  end

  def session_expired(socket) do
    {:noreply, socket}
  end

  def changeset_to_base64(ch = %{changes: pk}) do
    %{ch | changes:
      %{pk | private: Base.encode64(pk.private, padding: false),
        public: Base.encode64(pk.public, padding: false)}
    }
  end

  def changeset_from_base64(ch = %{changes: pk = %{public: public}}) do
    bad_format_err = "must be Base64 encoded, no padding"
    case Base.decode64(public, padding: false) do
      {:ok, pub} ->
        {
          :ok,
          %{ch | changes: %{pk | public: pub, private: ""}}
        }
      :error -> {:error, Changeset.add_error(ch, :public, bad_format_err)}
    end
  end
end
