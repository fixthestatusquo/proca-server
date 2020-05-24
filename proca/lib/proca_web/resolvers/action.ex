defmodule ProcaWeb.Resolvers.Action do
  # import Ecto.Query
  import Ecto.Changeset

  alias Proca.{Supporter, Action, ActionPage, Contact, Source, Consent}
  alias Proca.Repo

  alias ProcaWeb.Helper

  def get_action_page(%{action_page_id: id}) do
    case ActionPage.find(id) do
      nil -> {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page -> {:ok, action_page}
    end
  end

  defp add_tracking(sig, %{tracking: tr}) do
    with {:ok, src} <- Source.get_or_create_by(tr) do
      put_assoc(sig, :source, src)
    else
      # XXX report this somehow? This is a strange situation where we could not insert Source.
      # even though we retried 2 times
      {:error, _m} -> sig
    end
  end

  defp add_tracking(sig, %{}) do
    sig
  end

  defp increment_counter(%{campaign_id: cid, action_page_id: apid}) do
    Proca.Server.Stats.increment(cid, apid)
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
    %{contact_ref: contact_ref}
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

  def link_references(supporter, %{link_refs: refs}) do
    Action.link_refs_to_supporter(refs, supporter)
  end

  def link_references(_supporter, %{}) do
  end

  def add_action_contact(_, params = %{action: action}, _) do
    with {:ok, action_page} <- get_action_page(params),
         create_supporter = %{valid?: true} <-
           Supporter.create_supporter(action_page, params)
           |> add_tracking(params),
         {:ok, supporter} <- Repo.insert(create_supporter),
         change = %{valid?: true} <-
           Action.create_for_supporter(action, supporter, action_page) |> add_tracking(params),
         {:ok, new_action} <- Repo.insert(change) do

      link_references(supporter, params)
      increment_counter(new_action)

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

  def add_action(_, params = %{contact_ref: _cref, action: action_attrs}, _) do
    with {:ok, action_page} <- get_action_page(params),
         {:ok, supporter} <- get_supporter(action_page, params),
         change = %{valid?: true} <-
           Action.create_for_supporter(action_attrs, supporter, action_page)
           |> add_tracking(params),
         {:ok, new_action} <- Repo.insert(change) do
      increment_counter(new_action)

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
