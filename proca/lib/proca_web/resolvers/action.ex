defmodule ProcaWeb.Resolvers.Action do
  # import Ecto.Query
  import Ecto.Changeset
  alias Ecto.Multi

  alias Proca.{Supporter, Action, ActionPage, Contact, Source}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Repo
  alias Proca.Server.Notify

  alias ProcaWeb.Helper

  defp get_action_page(%{action_page_id: id}) do
    case ActionPage.find(id) do
      nil -> {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page -> {:ok, action_page |> Repo.preload([:org, [campaign: :org]])}
    end
  end

  defp add_tracking(action, %{tracking: tr}) do
    case Source.get_or_create_by(tr) do
      {:ok, src} -> put_assoc(action, :source, src)
      _ -> action
    end
  end

  defp add_tracking(action, %{}) do
    action
  end

  defp output(%{first_name: first_name, fingerprint: fpr}) do
    %{
      first_name: first_name,
      contact_ref: Supporter.base_encode(fpr)
    }
  end

  defp output(%{fingerprint: fpr}) do
    %{
      contact_ref: Supporter.base_encode(fpr)
    }
  end

  defp output(contact_ref) when is_bitstring(contact_ref) do
    %{
      contact_ref: contact_ref
    }
  end

  def get_supporter(action_page, %{contact_ref: cref}) do
    case Supporter.base_decode(cref) do
      {:ok, fpr} ->
        case Supporter.find_by_fingerprint(fpr, action_page.org_id) do
          s = %Supporter{} -> {:ok, s}
          nil -> {:ok, cref}
        end

      :error ->
        {:error, "contact_ref: Cannot decode from Base64url"}
    end
  end

  def link_references(supporter, %{contact_ref: ref}) do
    Action.link_refs_to_supporter([ref], supporter)
  end

  # when we create new supporter, but there is no contact_ref to link
  def link_references(supporter, %{}) do
  end

  def add_action_contact(_, params = %{action: action, contact: contact, privacy: priv}, _) do
    case Multi.new()
    |> Multi.run(:action_page, fn repo, _m ->
      get_action_page(params)
    end)
    |> Multi.run(:data, fn _repo, %{action_page: action_page} ->
      Helper.validate(ActionPage.new_data(contact, action_page))
    end)
    |> Multi.run(:supporter, fn repo, %{data: data, action_page: action_page} ->
      Supporter.new_supporter(data, action_page)
      |> Supporter.add_contacts(Data.to_contact(data, action_page), action_page, struct!(Privacy, priv)) 
      |> add_tracking(params)
      |> repo.insert()
    end)
    |> Multi.run(:action, fn repo, %{supporter: supporter, action_page: action_page} ->
      Action.create_for_supporter(action, supporter, action_page)
      |> add_tracking(params)
      |> put_change(:with_consent, true)
      |> repo.insert()
    end)
    |> Multi.run(:link_references, fn repo, %{supporter: supporter} ->
      {:ok, link_references(supporter, params)}
    end)
    |> Repo.transaction()
      do
      {:ok, %{supporter: supporter, action: action}} ->
        Notify.action_created(action, true)
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, _v, msg, _ch} ->
        {:error, msg}

      _e ->
        {:error, "other error?"}

    end
  end

  def add_action(_, params = %{contact_ref: _cref, action: action_attrs}, _) do
    case Multi.new()
    |> Multi.run(:action_page, fn repo, _m ->
      get_action_page(params)
    end)
    |> Multi.run(:supporter, fn _repo, %{action_page: action_page} ->
      get_supporter(action_page, params)
    end)
    |> Multi.run(:action, fn repo, %{action_page: action_page, supporter: supporter} ->
      Action.create_for_supporter(action_attrs, supporter, action_page)
      |> add_tracking(params)
      |> repo.insert()
    end)
    |> Repo.transaction()
      do
      {:ok, %{supporter: supporter, action: action}} ->
        Notify.action_created(action, false)
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, v, msg, ch} ->
        IO.inspect({v, msg, ch}, label: "Second error")
        {:error, msg}

      _e ->
        {:error, "other error?"}
    end
  end

  def link_actions(_, params = %{link_refs: refs}, _) do
    with {:ok, action_page} <- get_action_page(params),
         {:ok, supporter = %Supporter{}} <- get_supporter(action_page, params)
      do
      Action.link_refs_to_supporter(refs, supporter)
      {:ok, output(supporter)}
      else
        _ -> {:error, "ActionPage or contact not found"}
    end
  end
end
