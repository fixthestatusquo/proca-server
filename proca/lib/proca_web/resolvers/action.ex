defmodule ProcaWeb.Resolvers.Action do
  # import Ecto.Query
  import Ecto.Changeset

  alias Proca.{Supporter, Action, ActionPage, Contact, Source, Consent}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Repo

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

  defp increment_counter(%{campaign_id: cid, action_type: atype}, new_supporter) do
    Proca.Server.Stats.increment(cid, atype, new_supporter)
  end

  defp process_action(action) do
    Proca.Server.Processing.process_async(action)
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

  def add_action_contact_tx(a, params, b) do
    case Repo.transaction(fn ->
      add_action_contact(a, params, b)
    end) do
      {:ok, rv} -> rv
      e -> e
    end
  end

  def add_action_contact(_, params = %{action: action, contact: contact, privacy: priv}, _) do
    with {:ok, action_page} <- get_action_page(params),
         data1 = %{valid?: true} <- ActionPage.new_data(contact, action_page),
         data <- apply_changes(data1),
         contact = %{valid?: true} <- Data.to_contact(data, action_page),
         supporter1 = %{valid?: true} <- Supporter.new_supporter(data, action_page),
         supporter2 <- Supporter.add_contacts(supporter1, contact, action_page, struct!(Privacy, priv))
         |> add_tracking(params),
         {:ok, supporter} <- Repo.insert(supporter2),
         action1 = %{valid?: true} <-
           Action.create_for_supporter(action, supporter, action_page)
           |> add_tracking(params)
           |> put_change(:with_consent, true),
         {:ok, new_action} <- Repo.insert(action1) do

      link_references(supporter, params)
      increment_counter(new_action, true)
      process_action(new_action)

      # format return value 
      {:ok, output(supporter)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, Helper.format_errors(changeset)}

      {:error, msg} ->
        {:error, msg}

      _ ->
        {:error, "other error?"}
    end
  end

  def add_action_tx(a, params, b) do
    case Repo.transaction(fn ->
          add_action(a, params, b)
        end) do
      {:ok, rv} -> rv
      e -> e
    end
  end

  def add_action(_, params = %{contact_ref: _cref, action: action_attrs}, _) do
    with {:ok, action_page} <- get_action_page(params),
         {:ok, supporter} <- get_supporter(action_page, params),
         change = %{valid?: true} <-
           Action.create_for_supporter(action_attrs, supporter, action_page)
           |> add_tracking(params),
         {:ok, new_action} <- Repo.insert(change) do
      increment_counter(new_action, false)
      process_action(new_action)

      {:ok, output(supporter)}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, Helper.format_errors(changeset)}

      {:error, msg} ->
        {:error, msg}

      _ ->
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
