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
    case ActionPage.one(id: id, preload: [:org, [campaign: [:org, :mtt]]]) do
      nil -> {:error, "action_page_id: Cannot find Action Page with id=#{id}"}
      action_page -> {:ok, action_page}
    end
  end

  defp check_location_against_referer(tr, referer) do
    location = Map.get(tr, :location)
    Map.put(tr, :location, Source.get_tracking_location(location, referer))
  end

  # utms given and referer header maybe
  defp get_tracking(%{tracking: tr}, referer) do
    case tr
         |> check_location_against_referer(referer)
         |> Source.get_or_create_by() do
      {:ok, src} -> {:ok, src}
      _ -> {:ok, nil}
    end
  end

  # only refer header given, we provide n/a utm values to better look in stats
  defp get_tracking(%{}, referer) when is_bitstring(referer) do
    get_tracking(%{tracking: %{}}, referer)
  end

  # no referer, programmatic api use
  defp get_tracking(%{}, nil) do
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
        case Supporter.one(
               contact_ref: fpr,
               org_id: action_page.org_id,
               limit: 1,
               order_by: [desc: :id]
             ) do
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

  # handle custom_fields as well as 
  defp merge_old_fields_format(action_attrs) do
    {fields_attr, attrs} = Map.pop(action_attrs, :fields, %{})

    attrs =
      Map.put(
        attrs,
        :fields,
        Map.merge(Proca.Field.list_to_map(fields_attr), Map.get(attrs, :custom_fields, %{}))
      )

    attrs
  end

  def add_action_contact(
        _,
        params = %{action: action_attrs, contact: contact, privacy: priv},
        resolution = %{context: context}
      ) do
    action_attrs = merge_old_fields_format(action_attrs)

    case Multi.new()
         |> Multi.run(:action_page, fn _repo, _m ->
           get_action_page(params)
         end)
         |> Multi.run(:data, fn _repo, %{action_page: action_page} ->
           Helper.validate(ActionPage.new_data(contact, action_page))
         end)
         |> check_captcha(resolution)
         |> Multi.run(:source, fn _repo, _ ->
           get_tracking(params, get_in(context, [:headers, "referer"]))
         end)
         |> Multi.run(:supporter, fn repo,
                                     %{data: data, action_page: action_page, source: source} ->
           Supporter.new_supporter(data, action_page)
           |> Supporter.add_contacts(
             Data.to_contact(data, action_page),
             action_page,
             struct!(Privacy, priv)
           )
           |> put_assoc(:source, source)
           |> repo.insert()
         end)
         |> Multi.run(:action, fn repo,
                                  %{
                                    supporter: supporter,
                                    action_page: action_page,
                                    source: source
                                  } ->
           Action.build_for_supporter(action_attrs, supporter, action_page)
           |> put_assoc(:source, source)
           |> put_change(:with_consent, true)
           |> repo.insert()
         end)
         |> Multi.run(:link_references, fn _repo, %{supporter: supporter} ->
           {:ok, link_references(supporter, params)}
         end)
         |> Repo.transaction_and_notify(:add_action_contact, all_error: true) do
      {:ok, result = %{supporter: supporter}} ->
        audit_captcha(result)
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, _v, msg, _ch} ->
        {:error, msg}

      _e ->
        {:error, "other error?"}
    end
  end

  def add_action(_, params = %{contact_ref: _cref, action: action_attrs}, %{context: context}) do
    action_attrs = merge_old_fields_format(action_attrs)

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
         |> Multi.run(:action, fn repo,
                                  %{
                                    action_page: action_page,
                                    supporter: supporter,
                                    source: source
                                  } ->
           Action.build_for_supporter(action_attrs, supporter, action_page)
           |> put_assoc(:source, source)
           |> repo.insert()
         end)
         |> Repo.transaction_and_notify(:add_action, all_error: true) do
      {:ok, %{supporter: supporter, action: action}} ->
        {:ok, output(supporter)}

      {:error, _v, %Ecto.Changeset{} = changeset, _chj} ->
        {:error, Helper.format_errors(changeset)}

      {:error, v, msg, ch} ->
        error(why: "unmatched error in addAction", match: {:error, v, msg, ch})
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

  defp check_captcha(multi, resolution) do
    multi
    |> Multi.run(:captcha, fn _repo, _ ->
      case ProcaWeb.Resolvers.Captcha.verify(resolution) do
        resolution = %{state: :resolved} ->
          {:error, resolution.errors}

        resolution ->
          {:ok, Map.get(resolution.private, :captcha_meta)}
      end
    end)
  end

  defp audit_captcha(%{
         captcha_meta: meta,
         supporter: %{id: sid, fingerprint: fpr},
         action: %{id: aid}
       }) do
    Repo.insert(%EctoTrail.Changelog{
      actor_id: Integer.to_string(sid),
      resource: "captcha_actions",
      resource_id: Integer.to_string(aid),
      changeset: meta
    })
  end

  defp audit_captcha(_meta), do: nil
end
