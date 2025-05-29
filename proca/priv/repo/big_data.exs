# Script for filling the database with arbitrary amounts of test data. You can run it as:
#
#     mix run priv/repo/big_data.exs
#

{opts, _, _} = OptionParser.parse(System.argv, strict: [
  orgs: :integer,
  campaigns: :integer,
  max_targets: :integer,
  max_message_contents: :integer,
  max_action_pages: :integer,
  max_sources: :integer,
  max_supporters: :integer,
  max_actions: :integer,
  max_messages: :integer,
])

rand_range = fn max ->
  last = Faker.random_between(1, max)
  Enum.map(1..last, fn i -> {i, last} end)
end

org_cnt = opts[:orgs] || 1
for org_i <- 0..org_cnt-1 do
  org_name = Faker.Company.name()
  {:ok, org} = Proca.Repo.insert(%Proca.Org{name: org_name, title: org_name})
  IO.puts("=> Created Org #{org_i}/#{org_cnt}: '#{org_name}' -> ID #{org.id}")

  # TODO: staffers

  campaign_cnt = opts[:campaigns] || 1
  for campaign_i <- 0..campaign_cnt-1 do
    campaign_name = "Stop #{Faker.Industry.industry()} and #{Faker.Industry.industry()} (By #{org_name})"
    {:ok, campaign} = Proca.Repo.insert(%Proca.Campaign{
      name: campaign_name, title: campaign_name, org: org
    })
    IO.puts("==> Created Campaign #{campaign_i}/#{campaign_cnt}: '#{campaign_name}' -> ID #{campaign.id}")

    targets = Enum.map(rand_range.(opts[:max_targets] || 4), fn {target_i, target_cnt} ->
      target_name = Faker.Person.name()
      {:ok, target} = Proca.Repo.insert(%Proca.Target{
        name: target_name, area: Faker.Address.city(), external_id: Faker.UUID.v4(), locale: "en_US", campaign: campaign,
      })
      email_addr = Faker.Internet.email()
      {:ok, email} = Proca.Repo.insert(%Proca.TargetEmail{
        email: email_addr, target: target,
      })
      IO.puts("===> Created Target #{target_i}/#{target_cnt}: '#{target_name}' @ '#{email_addr}' -> ID #{target.id}, Email ID #{email.id}")
      target
    end)

    message_contents = Enum.map(rand_range.(opts[:max_message_contents] || 3), fn {message_content_i, message_content_cnt} ->
      subject = Faker.Lorem.sentence(2..6)
      {:ok, message_content} = Proca.Repo.insert(%Proca.Action.MessageContent{
        subject: subject,
        body: Faker.Lorem.paragraph(2..8)
      })
      IO.puts("===> Created MessageContent #{message_content_i}/#{message_content_cnt}: '#{subject}' -> ID #{message_content.id}")
      message_content
    end)

    for {action_page_i, action_page_cnt} <- rand_range.(opts[:max_action_pages] || 3) do
      action_page_name = "Page #{action_page_i} to #{campaign_name}"
      {:ok, action_page} = Proca.Repo.insert(%Proca.ActionPage{
        locale: "en_GB", name: action_page_name, org: org, campaign: campaign,
      })
      IO.puts("===> Created ActionPage #{action_page_i}/#{action_page_cnt}: '#{action_page_name}' -> ID #{action_page.id}")

      sources = Enum.map(rand_range.(opts[:max_sources] || 3), fn {source_i, source_cnt} ->
        source_url = Faker.Internet.url()
        {:ok, source} = Proca.Repo.insert(%Proca.Source{location: source_url})
        IO.puts("====> Created Source #{source_i}/#{source_cnt}: '#{source_url}' -> ID #{source.id}")
        source
      end)

      for {supporter_i, supporter_cnt} <- rand_range.(opts[:max_supporters] || 32) do
        supporter_first_name = Faker.Person.first_name()
        supporter_status = Faker.Util.pick([:new, :confirming, :rejected, :accepted, :accepted, :accepted, :accepted])
        email_addr = Faker.Internet.email()
        source = Faker.Util.pick(sources)
        fingerprint = Faker.UUID.v4()
        {:ok, supporter} = Proca.Repo.insert(%Proca.Supporter{
          first_name: supporter_first_name, email: email_addr, campaign: campaign, action_page: action_page, source: source,
          processing_status: supporter_status, fingerprint: fingerprint,
        })
        IO.puts("====> Created Supporter #{supporter_i}/#{supporter_cnt}: '#{supporter_first_name}' @ '#{email_addr}' ref '#{fingerprint}', #{supporter_status} -> ID #{supporter.id}")

        # for {contact_i, contact_cnt} <- rand_range.(opts[:max_contacts] || 2) do # <<<< Currently, having one is hardcoded in some places like export_actions
        {:ok, contact} = Proca.Repo.insert(%Proca.Contact{
          supporter: supporter, org: org, payload: "{}",
          communication_consent: Faker.Util.pick([true, true, true, false]),
          communication_scopes: ["email"],
          delivery_consent: Faker.Util.pick([true, true, true, false]),
        })
        IO.puts("=====> Created Contact -> ID #{contact.id}")
        # end

        for {action_i, action_cnt} <- rand_range.(opts[:max_actions] || 2) do
          action_ref = Faker.UUID.v4()
          action_status = Faker.Util.pick([:new, :confirming, :rejected, :accepted, :accepted, :delivered, :delivered, :delivered, :delivered])
          action_type = Faker.Util.pick(["share", "signature", "petition"])
          {:ok, action} = Proca.Repo.insert(%Proca.Action{
            ref: action_ref, action_type: action_type, supporter: supporter, campaign: campaign, action_page: action_page, source: source,
            with_consent: Faker.Util.pick([true, false]),
            processing_status: action_status,
          })
          IO.puts("=====> Created Action #{action_i}/#{action_cnt}: #{action_type} ref '#{action_ref}', #{action_status} -> ID #{action.id}")

          for {message_i, message_cnt} <- rand_range.(opts[:max_messages] || 4) do
            target = Faker.Util.pick(targets)
            sent = Faker.Util.pick([true, false])
            delivered = sent && Faker.Util.pick([true, false])
            opened = delivered && Faker.Util.pick([true, false])
            clicked = opened && Faker.Util.pick([true, false])
            {:ok, message} = Proca.Repo.insert(%Proca.Action.Message{
              sent: sent, delivered: delivered, opened: opened, clicked: clicked, action: action, target: target,
              message_content: Faker.Util.pick(message_contents),
            })
            IO.puts("======> Created Message #{message_i}/#{message_cnt} to '#{target.name}' (#{target.id}) -> ID #{message.id}")
          end

          if Faker.Util.pick([true, false]) do
            donation_amount = Faker.random_between(1, 420)
            {:ok, donation} = Proca.Repo.insert(%Proca.Action.Donation{
              amount: donation_amount, action: action,
            })
            IO.puts("======> Created Donation of #{donation_amount} monies -> ID #{donation.id}")
          end
        end
      end
    end

  end
end
