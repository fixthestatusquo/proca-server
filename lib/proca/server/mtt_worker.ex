defmodule Proca.Server.MTTWorker do
  @moduledoc """
  MTT worker sends MTT emails for particular campaign.

  It will only send emails in the time window, defined by:
  - `campaign.mtt.startAt` {start_day, start_time}
  - `campaign.mtt.endAt` {end_day, end_time}
  - we are in time window only if `start_day <= today <= end_day` AND `start_time <= current_time <= end_time`.

  In each cycle (when run) MTTWorker calculates how many cycles has already passed (PASSED) and how many remain until end of sending (REMAIN).
  It then checks, if we already sent `ALL_EMAILS_FOR_TARGET*PASSED/(PASSED+REMAINED)` emails, and if not, it sends enough emails to that target to match the proportion.
  This way the MTT sending is spread linearly throughout all sending period.

  Worker will only send to targets, who have a good email (with `emailStatus`=`NONE`, not bouncing).

  The worker only picks the messages to send; delivery goes through the org's
  `wrk.N.mtt` RabbitMQ queue (`Proca.Server.MTTContext.dispatch_message/2`,
  consumed by `Proca.Stage.MTT`). Test emails are sent separately and
  instantly, pushed to the global `wrk.mtt.test` queue by
  `Proca.Stage.Processing`.
  """

  alias Proca.Repo
  import Ecto.Query

  alias Proca.Campaign
  alias Proca.Action.Message
  alias Proca.Server.MTTContext

  require Logger

  def process_mtt_campaign(campaign) do
    campaign = Repo.preload(campaign, [:mtt, [org: :email_backend]])

    if campaign.org.email_backend != nil and within_sending_window(campaign) do
      {cycle, all_cycles} = calculate_cycles(campaign)
      target_ids = get_sendable_target_ids(campaign)

      :telemetry.execute(
        [:proca, :mtt],
        %{sendable_targets: length(target_ids), current_cycle: cycle, all_cycles: all_cycles},
        %{campaign_id: campaign.id, campaign_name: campaign.name}
      )

      Logger.info(
        "MTT worker #{campaign.name}: #{length(target_ids)} targets, send cycle #{cycle}/#{all_cycles}"
      )

      Enum.chunk_every(target_ids, 10)
      |> Enum.each(fn target_ids ->
        emails_to_send = get_emails_to_send(target_ids, {cycle, all_cycles})

        Logger.info(
          "MTT worker #{campaign.name}: Sending #{length(emails_to_send)} emails for chunk of targets: #{inspect(target_ids)}, cycle #{cycle}/#{all_cycles}"
        )

        :telemetry.execute(
          [:proca, :mtt],
          %{messages_sent: length(emails_to_send)},
          %{campaign_id: campaign.id, campaign_name: campaign.name}
        )

        # Route through the org's wrk.N.mtt queue. A queue outage leaves the
        # database message unsent for a later run.
        Enum.each(emails_to_send, fn msg ->
          MTTContext.dispatch_message(%{msg.target | campaign: campaign}, msg)
        end)
      end)
    else
      if campaign.org.email_backend == nil do
        Logger.error(
          "MTT #{campaign.name} cannot send because #{campaign.org.name} org does not have an email backend"
        )
      end

      :noop
    end
  end

  @doc """
  Queries for targets with at least one email that is sendable (status none)
  Returns list of ids
  """
  def get_sendable_target_ids(%Campaign{id: id}) do
    from(t in Proca.Target,
      join: c in assoc(t, :campaign),
      join: te in assoc(t, :emails),
      where:
        c.id == ^id and
          te.email_status in [:active, :none],
      distinct: t.id,
      select: t.id
    )
    |> Repo.all()
  end

  @doc """
  Return {current_cycle, all_cycles} tuple to know where we are in the schedule
  """
  def calculate_cycles(_campaign = %Campaign{mtt: %{start_at: start_at, end_at: end_at}}) do
    # cycles run in office hours, not 24h, per day it is:
    cycles_per_day = calculate_cycles_in_day(start_at, end_at)
    # cycles left today:
    cycles_today = calculate_cycles_in_day(Time.utc_now(), end_at)

    # add +1 to count current day. We validated end_at > start_at, so it's 1 day even if it's a 5 minute one
    all_days = Date.diff(end_at, start_at) + 1
    # how many days behind us
    days_left = Date.diff(end_at, Date.utc_today())

    total_cycles = all_days * cycles_per_day

    {
      # cycles left are rounded now, so by substracting we will round up - so we are not left with any messages at the end of schedule
      total_cycles - (days_left * cycles_per_day + cycles_today),
      total_cycles
    }
  end

  def calculate_cycles_in_day(start_time, end_time) do
    mins_per_cycles = Application.get_env(:proca, Proca)[:mtt_cycle_time]
    time_diff = Integer.floor_div(Time.diff(end_time, start_time, :second), 60)

    div(time_diff, mins_per_cycles)
  end

  @doc """
  Check if we are now in sending days, and also in sending hours.

  The Server.MTT select only campaigns in day-window already, but it is worth to double check here.
  """
  def within_sending_window(%{mtt: %{start_at: start_at, end_at: end_at}}) do
    now = DateTime.utc_now()

    in_sending_days =
      DateTime.compare(now, start_at) == :gt and DateTime.compare(end_at, now) == :gt

    start_time = DateTime.to_time(start_at)
    end_time = DateTime.to_time(end_at)

    in_sending_time = Time.compare(now, start_time) == :gt and Time.compare(end_time, now) == :gt

    in_sending_days and in_sending_time
  end

  def get_emails_to_send(target_ids, {cycle, all_cycles}) do
    # Subquery to count delivered/goal messages for each target
    progress_per_target =
      Message.select_by_targets(target_ids, [false, true])
      |> select([m, t, mtt, a], %{
        target_id: t.id,
        goal: count(m.id) * ^cycle / ^all_cycles,
        sent: fragment("count(?) FILTER (WHERE sent)", m.id)
      })
      |> group_by([m, t, mtt, a], t.id)

    # Subquery to rank unsent message ids and select only these need to meet current goal
    unsent_per_target_ids =
      Message.select_by_targets(target_ids, false)
      |> select([m, t, mtt, a], %{
        message_id: m.id,
        target_id: t.id,
        rank: fragment("RANK() OVER (PARTITION BY ? ORDER BY ?)", t.id, m.id)
      })
      |> subquery()
      |> join(:inner, [r], p in subquery(progress_per_target), on: r.target_id == p.target_id)
      # <= because rank is 1-based
      |> where([r, p], p.sent + r.rank <= p.goal)
      |> select([r, p], r.message_id)
      |> limit(^max_messages_per_cycle())

    # Finally, fetch these messages with associations in one go
    Repo.all(
      from(m in Message,
        where: m.id in subquery(unsent_per_target_ids),
        preload: [[target: :emails], [action: [:supporter, action_page: :org]], :message_content]
      )
    )
  end

  defp max_messages_per_cycle() do
    max_messages = Application.get_env(:proca, __MODULE__)[:max_messages_per_cycle]

    if max_messages < 1 do
      1
    else
      max_messages
    end
  end
end
