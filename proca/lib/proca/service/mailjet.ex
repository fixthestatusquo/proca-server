defmodule Proca.Service.Mailjet do
  @moduledoc """
  Mailjet Email Backend
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service}
  alias Proca.Service.EmailTemplate

  @api_url "https://api.mailjet.com/v3"
  @template_path "/REST/template"

  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def list_templates(%Org{template_backend: %Service{} = srv}) do
    case Service.json_request(srv, "#{@api_url}#{@template_path}", auth: :basic) do
      {:ok, 200, %{"Data" => templates}} -> templates |> Enum.map(&template_from_json/1)
      {:error, err} -> {:error, err}
      _x -> {:error, "unexpected return from mailjet list templates"}
    end
  end

  defp template_from_json(data) do
    %EmailTemplate{
      ref: Integer.to_string(data["ID"]),
      name: data["Name"]
    }
  end


end
