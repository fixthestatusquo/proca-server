defmodule Proca.Service.EmailTemplate do
  @moduledoc """
  Models an email tempalate to be rendered into a thank you email, etc.
  """

  alias __MODULE__
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  alias Proca.Org
  alias Swoosh.Email
  import Proca.Stage.Support, only: [camel_case_keys: 1]
  import Ecto.Changeset

  schema "email_templates" do
    field :name, :string, null: false
    field :locale, :string, null: false
    # only for external ref (could be string)
    field :ref, :string, null: true, virtual: true

    field :subject, :string, null: false
    field :html, :string, null: false
    field :text, :string, null: true

    field :compiled, :map, null: true, virtual: true

    belongs_to :org, Proca.Org
  end

  @doc """
  Changeset, only used for local templates stored in DB
  """
  def changeset(service, attrs) do
    related = Map.take(attrs, [:org])

    cast(service, attrs, [:name, :locale, :ref, :subject, :html, :text])
    |> validate_required([:name, :locale, :subject, :html])
    |> validate_format(:name, ~r/^[\w\d_ -]+$/)
    |> change(related)
    |> validate_template(:subject)
    |> validate_template(:html)
    |> validate_template(:text)
    |> Proca.Action.MessageContent.fix_subject()
  end

  def changeset(attrs), do: changeset(%EmailTemplate{}, attrs)

  def validate_template(changeset, field) do
    validate_change(changeset, field, fn _f, tmplstr ->
      try do
        compile_string(tmplstr)
        []
      rescue
        error ->
          case error do
            %{original: {:incorrect_format, reason}} ->
              [
                {field,
                 {"Invalid mustache template format in #{field}: #{inspect(reason)}", [reason]}}
              ]

            e ->
              [{field, "Invalid template in #{field}: #{inspect(e)}"}]
          end
      end
    end)
  end

  def all(queryable, [{:org, %Org{id: org_id}} | criteria]) do
    import Ecto.Query

    queryable
    |> where([t], t.org_id == ^org_id)
    |> all(criteria)
  end

  def all(queryable, [{:name, name} | criteria]) when is_bitstring(name) do
    import Ecto.Query

    queryable
    |> where([t], t.name == ^name)
    |> all(criteria)
  end

  def all(queryable, [{:locale, locale} | criteria]) when is_bitstring(locale) do
    import Ecto.Query

    queryable
    |> where([t], t.locale == ^locale)
    |> all(criteria)
  end

  def all(queryable, [{:locale, locale} | criteria]) when is_nil(locale) do
    import Ecto.Query

    queryable
    |> limit([t], 1)
    |> all(criteria)
  end

  def compile(t = %EmailTemplate{subject: subject, html: html, text: text}) do
    Sentry.Context.set_extra_context(%{
      template_id: t.id,
      template_name: t.name,
      locale: t.locale
    })

    %{
      t
      | compiled: %{
          subject: compile_string(subject),
          html: compile_string(html),
          text: compile_string(text)
        }
    }
  end

  def compile_string(nil), do: nil

  def compile_string(m) do
    try do
      :bbmustache.parse_binary(m)
    rescue
      error ->
        Sentry.capture_exception(error, stacktrace: __STACKTRACE__)
        # TODO: return proper error instead of reraising
        reraise Sentry.CrashError.exception(error.original), __STACKTRACE__
    end
  end

  # when end is_tuple(m) do
  def render_string(m, vars) do
    :bbmustache.compile(m, vars, key_type: :binary)
  end

  @spec render(Email, EmailTemplate) :: Email
  def render(
        email = %Email{},
        %EmailTemplate{
          compiled: %{
            subject: ts,
            html: th,
            text: tt
          }
        }
      ) do
    vars = camel_case_keys(email.assigns)

    %Email{
      email
      | subject: render_string(ts, vars),
        html_body: render_string(th, vars),
        text_body: if(is_nil(tt), do: nil, else: render_string(tt, vars))
    }
  end

  def render(email, tmpl = %EmailTemplate{compiled: nil}) do
    render(email, compile(tmpl))
  end

  @doc """
  Validate the template set in changeset is valid for owning Org.
  (both action pages and orgs have template attributes)

  If no template backend is configured, return success - we assume that user
  might use an external template.

  """
  def validate_exists(%Ecto.Changeset{} = changeset, field) do
    alias Proca.Service.EmailTemplateDirectory
    alias Ecto.Changeset
    alias Proca.{Org, ActionPage, MTT}

    Changeset.validate_change(changeset, field, fn f, template ->
      org =
        case Changeset.apply_changes(changeset) do
          %ActionPage{org: %Org{} = o} -> o
          %ActionPage{org_id: org_id} -> Org.one(id: org_id)
          %Org{} = o -> o
          %MTT{} = mtt -> Proca.Repo.preload(mtt, campaign: :org).campaign.org
        end

      case org.email_backend_id do
        nil ->
          []

        _id ->
          case EmailTemplateDirectory.by_name_reload(org, template) do
            {:ok, _} -> []
            :not_found -> [{f, "Template not found"}]
          end
      end
    end)
  end

  def html_from_text(text) do
    String.replace(text, ~r/\n/, "<br/>")
  end
end
