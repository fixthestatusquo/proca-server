defmodule Proca.Service.EmailTemplateDirectory do 
  use GenServer
  alias Proca.{Service, Org, Repo}
  alias Proca.Service.{EmailBackend,EmailTemplate}
  import Ex2ms

  def table_name(), do: :template_directory

  @impl true
  def init([]) do
    table = :ets.new(table_name(), [:set, :protected, :named_table])
    {:ok, %{table: table}}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def record(%Service{id: service_id}, %EmailTemplate{} = tmpl) do 
    {{service_id, tmpl.ref}, tmpl}
  end

  def delete_templates(%Org{template_backend_id: tb_id}) do
    spec = fun do {{id, ref}, template} when id == ^tb_id -> true end
    :ets.select_delete(table_name(), spec)
  end

  def load_templates(org) do 
    org = Repo.preload(org, [:template_backend])
    %Org{template_backend: tb} = org
    with {:ok, templates} <- EmailBackend.list_templates(org) do 
      delete_templates(org)

      for t <- templates do 
        :ets.insert(table_name(), record(tb, t))
      end

      {:ok, length(templates)}
    else 
      r = {:error, _reason} -> r
    end
  end


  @impl true
  def handle_cast({:load_templates, org}, st) do 
    load_templates(org)
    {:noreply, st}
  end

  @impl true 
  def handle_call({:load_templates, org}, _from, st) do 
    {:reply, load_templates(org), st}
  end

  def load_templates_async(org), do: GenServer.cast(__MODULE__, {:load_templates, org})
  def load_templates_sync(org), do: GenServer.call(__MODULE__, {:load_templates, org})
  
  def ref_by_name(%Org{template_backend_id: bid}, name) when is_integer(bid) and is_bitstring(name) do 
    spec = fun do {{id, ref}, %{name: n}} when id == ^bid and n == ^name -> ref end
    lookup = :ets.select table_name(), spec
    case lookup do 
      [ref] -> {:ok, ref}
      [] -> :not_found
    end
  end

  def ref_by_name(%Org{template_backend_id: bid}, name) when is_nil(bid) and is_bitstring(name) do 
    :not_configured
  end

  @doc """
  Lookup but if not found, reload the templates
  """
  def ref_by_name_reload(org, name) do 
    case ref_by_name(org, name) do 
      {:ok, ref} -> {:ok, ref}
      :not_found -> 
        load_templates_sync(org)
        ref_by_name(org, name)
      :not_configured = e -> e
    end
  end

 end
