defmodule Proca.Service.EmailTemplate do
  @moduledoc """
  Models an email tempalate to be rendered into a thank you email, etc.
  """

  defstruct [:name, :subject, :html, :text, :ref]

  @doc """
  Validate the template set in changeset is valid for :org of this entity.
  If no template backend is configured, return success - we assume that user might use an external template names in the AP.
  """
  def validate_exists(%Ecto.Changeset{} = changeset, field) do
    alias Proca.Service.EmailTemplateDirectory
    alias Ecto.Changeset
    alias Proca.Org

    Changeset.validate_change(changeset, field, fn f, template ->
      org =
        case Changeset.apply_changes(changeset) do
          %{org: %Org{}} = o -> o
          %{org_id: org_id} -> Org.one(id: org_id)
        end

      case EmailTemplateDirectory.ref_by_name_reload(org, template) do
        {:ok, _} -> []
        :not_configured -> []
        :not_found -> [{f, "Template not found"}]
      end
    end)
  end
end
