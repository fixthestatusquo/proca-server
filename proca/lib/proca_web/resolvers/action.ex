defmodule ProcaWeb.Resolvers.Action do
  @moduledoc """
  Resolvers for action related mutations
  """
  # import Ecto.Query
  import Ecto.Changeset
  import Logger
  alias Ecto.Multi

  alias Proca.{Supporter, Action, ActionPage, Source}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Repo

  alias ProcaWeb.Helper

  defp get_action_page(%{action_page_id: id}) do
    case ActionPage.one(id: id, preload: [:org, [campaign: :org]]) do
      nil -> {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page -> {:ok, action_page}
    end
  end

  defp add_tracking_location(tr, referer) do
    location = Map.get(tr, :location, nil)
    case Source.get_tracking_location(location, referer) do 
      nil -> Map.delete(tr, :location)
      url -> Map.put(tr, :location, url)
    end
  end


  # utms given and referer header
  defp get_tracking(%{tracking: tr}, referer) do
    case tr 
      |> add_tracking_location(referer)
      |> Source.get_or_create_by() 
    do
      {:ok, src} -> {:ok, src}
      _ -> {:ok, nil}
    end
  end

  # only refer header given, we provide n/a utm values to better look in stats
  defp get_tracking(%{}, referer) when is_bitstring(referer) do 
    get_tracking(%{tracking: %{
      source: "unknown", medium: "unknown", campaign: "unknown"
    }}, referer)
  end

  # no referer, programmatic api use
  defp get_tracking(%{}, _referer) do
    {:ok, nil}
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
  def link_references(_supporter, %{}) do
  end

  def add_action_contact(_, params = %{action: action, contact: contact, privacy: priv}, resolution = %{context: context}) do
    case Multi.new()
         |> Multi.run(:action_page, fn _repo, _m ->
           get_action_page(params)
         end)
         |> Multi.run(:data, fn _repo, %{action_page: action_page} ->
           Helper.validate(ActionPage.new_data(contact, action_page))
         end)
         |> Multi.run(:captcha, fn _repo, _ ->
           case ProcaWeb.Resolvers.Captcha.verify(resolution) do
             resolution = %{state: :resolved} ->
               {:error, resolution.errors}
             _ ->
               {:ok, Map.has_key?(resolution.extensions, :captcha)}
           end
         end)
         |> Multi.run(:source, fn _repo, _ -> 
          get_tracking(params, get_in(context, [:headers, "referer"]))
         end)
         |> Multi.run(:supporter, fn repo, %{data: data, action_page: action_page, source: source} ->
           Supporter.new_supporter(data, action_page)
           |> Supporter.add_contacts(
             Data.to_contact(data, action_page),
             action_page,
             struct!(Privacy, priv)
           )
           |> put_assoc(:source, source)
           |> repo.insert()
         end)
         |> Multi.run(:action, fn repo, %{supporter: supporter, action_page: action_page, source: source} ->
           Action.create_for_supporter(action, supporter, action_page)
           |> put_assoc(:source, source)
           |> put_change(:with_consent, true)
           |> repo.insert()
         end)
         |> Multi.run(:link_references, fn _repo, %{supporter: supporter} ->
           {:ok, link_references(supporter, params)}
         end)
         |> Repo.transaction() do
      {:ok, %{supporter: supporter, action: action}} ->
        Proca.Server.Notify.action_created(action, supporter)
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, _v, msg, _ch} ->
        {:error, msg}

      _e ->
        {:error, "other error?"}
    end
  end

  def add_action(_, params = %{contact_ref: _cref, action: action_attrs},  %{context: context}) do
    case Multi.new()
         |> Multi.run(:action_page, fn _repo, _m ->
           get_action_page(params)
         end)
         |> Multi.run(:supporter, fn _repo, %{action_page: action_page} ->
           get_supporter(action_page, params)
         end)
         |> Multi.run(:source, fn _repo, _ -> 
          get_tracking(params, get_in(context, [:headers, "referer"]))
         end)
         |> Multi.run(:action, fn repo, %{action_page: action_page, supporter: supporter, source: source} ->
           Action.create_for_supporter(action_attrs, supporter, action_page)
           |> put_assoc(:source, source)
           |> repo.insert()
         end)
         |> Repo.transaction() do
      {:ok, %{supporter: supporter, action: action}} ->
        Proca.Server.Notify.action_created(action)
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, v, msg, ch} ->
             error [why: "unmatched error in addAction", match: {:error, v, msg, ch}]
             {:error, msg}

      _e ->
        {:error, "other error?"}
    end
  end

  def link_actions(_, params = %{link_refs: refs}, _) do
    with {:ok, action_page} <- get_action_page(params),
         {:ok, supporter = %Supporter{}} <- get_supporter(action_page, params) do
      Action.link_refs_to_supporter(refs, supporter)
      {:ok, output(supporter)}
    else
      _ -> {:error, "ActionPage or contact not found"}
    end
  end
end
