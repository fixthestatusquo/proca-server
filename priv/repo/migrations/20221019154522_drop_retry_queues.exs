defmodule Proca.Repo.Migrations.DropRetryQueues do
  @moduledoc """
  RabbitMQ queues cannot be reconfigured - they need to be dropped and re-created.

  To remove "expires" config we need to drop them here in migration, and they will be re-created on proca launch.

  From now on the expiration is configured using RabbitMQ policies.
  """
  use Ecto.Migration

  def up do
    url = Proca.Pipes.queue_url()
    {:ok, conn} = AMQP.Connection.open(url, Proca.Pipes.Connection.connect_opts())
    {:ok, chan} = AMQP.Channel.open(conn)

    try do
      execute(fn ->
        repo().query!("SELECT id FROM orgs").rows
        |> Enum.map(&List.first/1)
        |> Enum.each(&AMQP.Queue.delete(chan, "org.#{&1}.fail"))
      end)
    rescue
      e ->
        AMQP.Channel.close(chan)
        AMQP.Connection.close(conn)
        reraise e, __STACKTRACE__
    end
  end

  def down do
  end
end
