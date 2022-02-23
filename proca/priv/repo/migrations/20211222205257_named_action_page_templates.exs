defmodule Proca.Repo.Migrations.NamedActionPageTemplates do
  use Ecto.Migration

  def up do
    rename table(:orgs), :email_opt_in, to: :supporter_confirm
    rename table(:orgs), :email_opt_in_template, to: :supporter_confirm_template

    rename table(:action_pages), :thank_you_template_ref, to: :thank_you_template

    alter table(:action_pages) do
      add :supporter_confirm_template, :string, null: true
    end
  end

  def down do
    rename table(:orgs), :supporter_confirm, to: :email_opt_in
    rename table(:orgs), :supporter_confirm_template, to: :email_opt_in_template

    rename table(:action_pages), :thank_you_template, to: :thank_you_template_ref

    alter table(:action_pages) do
      remove :supporter_confirm_template
    end
  end

  def template_ref_to_name do
    import Ecto.Query

    action_pages =
      Proca.Repo.all(from(o in Proca.ActionPage, preload: [org: [template_backend: :org]]))

    for ap <- action_pages, ap.org.template_backend != nil do
      o = ap.org.template_backend.org
      Proca.Service.EmailTemplateDirectory.load_templates_sync(o)

      case ap.thank_you_template do
        nil ->
          nil

        ref ->
          case Proca.Service.EmailTemplateDirectory.name_by_ref(o, String.to_integer(ref)) do
            {:ok, name} -> Proca.Repo.update!(Ecto.Changeset.change(ap, thank_you_template: name))
            _ -> throw("Action Page #{ap.name} (#{ap.id}): cannot find template name for #{ref}")
          end
      end
    end
  end
end
