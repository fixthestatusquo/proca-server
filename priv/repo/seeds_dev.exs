# MTT campaigns (drip and no-drip), a coalition petition
# with partners, double opt-in, email templates, integrations and bounces.
#
# =============================================================================
# HOW TO RUN
# =============================================================================
#
#   Requires the base seeds first (instance org + admin user):
#       ADMIN_EMAIL=you@example.org mix run seeds.exs
#
#   Default run (3000 supporters):
#       START_DAEMON_SERVERS=false mix run seeds_dev.exs
#
#   All options:
#       START_DAEMON_SERVERS=false mix run seeds_dev.exs \
#         --supporters 10000 --empty-content 10 --tag 2
#
#   --supporters N     total supporters across all campaigns (default 3000)
#   --empty-content N  MTT actions with an empty subject, to exercise
#                      Message.cancel_if_empty/1 (default 5)
#   --tag T            suffix added to org/campaign/page/source names, e.g.
#                      "climate-action-europe-2". Needed to run again: without
#                      it the script stops if the data already exists.
#
#   START_DAEMON_SERVERS=false keeps the MTT scheduler and other workers from
#   starting while the data is inserted.
#   ADMIN_EMAIL=... picks which user becomes owner of the campaign-owner orgs;
#   without it the first admin user in the DB is used.
#   SEED_TARGET_LIST_URL=... base URL for MTT target lists in the widget
#   config (default http://localhost:4000/t).
#   Restart a running dev server afterwards.
#
# =============================================================================
# WHAT IT CREATES
# =============================================================================
#
# 11 orgs (3 campaign owners + 8 partners), 2 MTT campaigns (drip and no-drip),
# a double opt-in coalition petition and a closed petition, with supporters,
# actions, messages, templates and widget config.
#
# Logins (staff users and their password), org ids, campaign ids, page ids and
# MTT target list URLs are appended to credentials.md in the project root
# (gitignored), so they are not lost in the terminal output. Each run adds a
# new section; nothing in the file is overwritten.
#
# NOTE: friends-of-rivers has a webhook push backend and umwelt-netz-de a detail
# backend pointing at *.example.net: new actions added through the API on these
# two orgs will try to call them and fail.
#

alias Proca.{Repo, Org, Campaign, ActionPage, Action, Supporter, Target, TargetEmail, MTT}
alias Proca.{Source, Staffer, Service, Permission}
alias Proca.Action.{Message, MessageContent, Donation}
alias Proca.Contact.BasicData
alias Proca.Service.EmailTemplate
alias Proca.Users.User
import Ecto.Query

{opts, _, _} =
  OptionParser.parse(System.argv(),
    strict: [supporters: :integer, empty_content: :integer, tag: :string]
  )

total_supporters = opts[:supporters] || 3000
empty_content_count = opts[:empty_content] || 5
suffix = if opts[:tag], do: "-#{opts[:tag]}", else: ""
password = "Password123!"

# Where the MTT widget loads its target list from (dev route ProcaWeb.DevTargetsController)
target_list_base = System.get_env("SEED_TARGET_LIST_URL", "http://localhost:4000/t")
hashed_password = Bcrypt.hash_pwd_salt(password)

now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
days_ago = fn d -> NaiveDateTime.add(now, -d * 86_400, :second) end

# Random moment between `from` and now, biased towards recent dates the way
# real campaigns get most of their signatures near launch and in pushes.
random_time_since = fn from ->
  span = max(NaiveDateTime.diff(now, from), 1)
  offset = trunc(span * :math.pow(:rand.uniform(), 0.6))
  NaiveDateTime.add(from, offset, :second)
end

weighted = fn list ->
  total = list |> Enum.map(&elem(&1, 1)) |> Enum.sum()
  r = :rand.uniform() * total

  Enum.reduce_while(list, 0, fn {item, w}, acc ->
    if acc + w >= r, do: {:halt, item}, else: {:cont, acc + w}
  end)
end

if is_nil(Org.one([:instance])) do
  raise "No instance org found - run `mix run seeds.exs` first"
end

if Repo.get_by(Org, name: "climate-action-europe" <> suffix) do
  raise "Seed data already exists. Run with --tag <something> to create another copy."
end

# ---------------------------------------------------------------------------
# Orgs, email backend, staff
# ---------------------------------------------------------------------------

countries = %{
  "fr" => %{country: "FR", postcode: fn -> "#{Enum.random(10..95)}0#{Enum.random(10..99)}" end},
  "de" => %{country: "DE", postcode: fn -> "#{Enum.random(10_000..99_999)}" end},
  "it" => %{country: "IT", postcode: fn -> "#{Enum.random(10_000..98_999)}" end},
  "pl" => %{country: "PL", postcode: fn -> "#{Enum.random(10..99)}-#{Enum.random(100..999)}" end},
  "es" => %{country: "ES", postcode: fn -> "#{Enum.random(10_000..52_999)}" end},
  "en" => %{country: "IE", postcode: fn -> "D#{Enum.random(10..24)}" end},
  "nl" => %{country: "NL", postcode: fn -> "#{Enum.random(1000..9999)} AB" end},
  "pt" => %{
    country: "PT",
    postcode: fn -> "#{Enum.random(1000..9999)}-#{Enum.random(100..999)}" end
  }
}

create_user = fn email ->
  Repo.get_by(User, email: email) ||
    Repo.insert!(%User{email: email, hashed_password: hashed_password, confirmed_at: now})
end

create_org = fn name, title ->
  name = name <> suffix
  domain = String.replace(name, "-", "") <> ".example.org"

  org =
    Repo.insert!(%Org{
      name: name,
      title: title,
      email_from: "contact@#{domain}",
      config: %{"lang" => "en"}
    })

  # Preview backend: emails are only logged and kept in memory, never sent
  backend =
    Repo.insert!(%Service{name: :preview, org_id: org.id, host: "", user: "", password: ""})

  org = Repo.update!(Ecto.Changeset.change(org, email_backend_id: backend.id))

  # No public key on purpose: contacts of orgs without an active key are
  # stored in plaintext, so they are readable in the dev DB.

  for {role, who} <- [owner: "owner", campaigner: "campaigner"] do
    user = create_user.("#{who}@#{domain}")

    Repo.insert!(%Staffer{
      org_id: org.id,
      user_id: user.id,
      perms: Permission.add(Proca.Staffer.Role.permissions(role))
    })
  end

  IO.puts("Org #{org.name} (#{org.id})")
  Map.put(org, :domain, domain)
end

lead = create_org.("climate-action-europe", "Climate Action Europe")
food = create_org.("fair-food-network", "Fair Food Network")
bees = create_org.("bee-alliance", "Bee Alliance")

partners =
  [
    {"friends-of-rivers", "Friends of the Rivers", "en"},
    {"reseau-climat-fr", "Réseau Climat France", "fr"},
    {"umwelt-netz-de", "Umwelt Netz Deutschland", "de"},
    {"clean-air-poland", "Czyste Powietrze Polska", "pl"},
    {"ecologistas-es", "Ecologistas en Acción", "es"},
    {"verdi-italia", "Verdi Italia Rete", "it"},
    {"groene-stad-nl", "Groene Stad", "nl"},
    {"quercus-pt", "Quercus Portugal", "pt"}
  ]
  |> Enum.map(fn {name, title, locale} -> {create_org.(name, title), locale} end)

# The admin created by seeds.exs becomes owner of the three campaign-owner orgs
# (lead, food, bees), so the data is visible right after logging in.
admin =
  case System.get_env("ADMIN_EMAIL") do
    nil -> Repo.one(from(u in User, where: u.perms > 0, order_by: u.id, limit: 1))
    email -> Repo.get_by(User, email: email)
  end

if admin do
  for org <- [lead, food, bees] do
    Repo.insert!(
      %Staffer{
        org_id: org.id,
        user_id: admin.id,
        perms: Permission.add(Proca.Staffer.Role.permissions(:owner))
      },
      on_conflict: :nothing
    )
  end
end

# Integrations on two partners: a CRM webhook that receives delivered actions,
# and a detail backend that is asked about each supporter before processing.
partner_org = fn name ->
  partners |> Enum.find(fn {o, _} -> o.name == name <> suffix end) |> elem(0)
end

rivers = partner_org.("friends-of-rivers")

push =
  Repo.insert!(%Service{
    name: :webhook,
    org_id: rivers.id,
    host:
      "https://crm.#{rivers.domain |> String.replace(".example.org", "")}.example.net/proca/actions",
    user: "proca",
    password: "webhook-secret"
  })

Repo.update!(Ecto.Changeset.change(rivers, push_backend_id: push.id))

umwelt = partner_org.("umwelt-netz-de")

detail =
  Repo.insert!(%Service{
    name: :webhook,
    org_id: umwelt.id,
    host:
      "https://members.#{umwelt.domain |> String.replace(".example.org", "")}.example.net/lookup",
    password: "Bearer detail-token"
  })

Repo.update!(Ecto.Changeset.change(umwelt, detail_backend_id: detail.id))

# ---------------------------------------------------------------------------
# Campaigns, MTT settings, targets, action pages
# ---------------------------------------------------------------------------

create_campaign = fn org, name, title, attrs ->
  {mtt, attrs} = Map.pop(attrs, :mtt)

  campaign =
    Repo.insert!(struct(%Campaign{org_id: org.id, name: name <> suffix, title: title}, attrs))

  if mtt, do: Repo.insert!(struct(%MTT{campaign_id: campaign.id}, mtt))

  IO.puts("  Campaign #{campaign.name} (#{campaign.id})")
  Repo.preload(campaign, [:org, :mtt])
end

create_page = fn campaign, org, path, locale ->
  page =
    Repo.insert!(%ActionPage{
      name: "#{org.domain}/#{path}#{suffix}",
      locale: locale,
      live: true,
      delivery: true,
      thank_you_template: "thank_you",
      campaign_id: campaign.id,
      org_id: org.id,
      # journey, components and texts come from the campaign config
      config: %{}
    })

  Repo.preload(page, [:org, campaign: [:org, :mtt]])
end

parties = ["EPP", "S&D", "Renew", "Greens/EFA", "ECR", "The Left", "PfE", "NI"]

create_targets = fn campaign, per_country, title_fn ->
  for {locale, %{country: cc}} <- countries, _ <- 1..per_country do
    first = Faker.Person.first_name()
    last = Faker.Person.last_name()
    slug = "#{first}.#{last}" |> String.downcase() |> String.replace(~r/[^a-z.]/, "")

    emails =
      [%TargetEmail{email: "#{slug}@parliament.example.net", email_status: :none}] ++
        if(:rand.uniform() < 0.3,
          do: [%TargetEmail{email: "#{slug}.office@example.net", email_status: :none}],
          else: []
        )

    # like real target lists: most addresses work, a few soft-bounced once or
    # twice, and a few are dead (hard bounce)
    emails =
      case :rand.uniform() do
        r when r < 0.05 ->
          Enum.map(emails, &%{&1 | email_status: :bounce, error: "550 5.1.1 mailbox unavailable"})

        r when r < 0.12 ->
          Enum.map(
            emails,
            &%{
              &1
              | email_status: :active,
                soft_bounce_count: Enum.random(1..2),
                error: "452 4.2.2 mailbox full"
            }
          )

        _ ->
          Enum.map(emails, &%{&1 | email_status: :active})
      end

    Repo.insert!(%Target{
      campaign_id: campaign.id,
      name: "#{first} #{last}",
      external_id: Ecto.UUID.generate(),
      area: cc,
      locale: locale,
      fields: %{"party" => Enum.random(parties), "title" => title_fn.(cc)},
      emails: emails
    })
  end
end

# 1. Coalition MTT, drip delivery, live
fossil =
  create_campaign.(lead, "fossil-subsidies", "Tell your MEP: end fossil fuel subsidies", %{
    start: Date.add(Date.utc_today(), -45),
    end: Date.add(Date.utc_today(), 30),
    mtt: %{
      start_at:
        DateTime.add(DateTime.utc_now(), -45 * 86_400, :second) |> DateTime.truncate(:second),
      end_at:
        DateTime.add(DateTime.utc_now(), 30 * 86_400, :second) |> DateTime.truncate(:second),
      drip_delivery: true,
      max_emails_per_hour: 30,
      timezone: "Europe/Brussels",
      test_email: "test@#{lead.domain}",
      cc_contacts: ["archive@#{lead.domain}"]
    }
  })

fossil_targets = create_targets.(fossil, 10, fn _ -> "MEP" end)

fossil_pages =
  [
    {create_page.(fossil, lead, "fossil/en", "en"), 30},
    {create_page.(fossil, lead, "fossil/fr", "fr"), 10},
    {create_page.(fossil, lead, "fossil/de", "de"), 10}
  ] ++ Enum.map(partners, fn {org, locale} -> {create_page.(fossil, org, "mep", locale), 7} end)

# 2. MTT without drip: messages go out right after the action
farm =
  create_campaign.(food, "farm-to-fork", "Ministers: keep the Farm to Fork promises", %{
    start: Date.add(Date.utc_today(), -20),
    end: Date.add(Date.utc_today(), 730),
    mtt: %{
      start_at:
        DateTime.add(DateTime.utc_now(), -20 * 86_400, :second) |> DateTime.truncate(:second),
      end_at:
        DateTime.add(DateTime.utc_now(), 730 * 86_400, :second) |> DateTime.truncate(:second),
      drip_delivery: false,
      timezone: "Europe/Paris",
      cc_sender: true
    }
  })

farm_targets = create_targets.(farm, 2, fn cc -> "Minister of Agriculture (#{cc})" end)

farm_pages = [
  {create_page.(farm, food, "farm-to-fork/en", "en"), 10},
  {create_page.(farm, food, "farm-to-fork/fr", "fr"), 6},
  {create_page.(farm, food, "farm-to-fork/it", "it"), 4}
]

# 3. Coalition petition with shares and donations
pesticides =
  create_campaign.(bees, "ban-pesticides", "Ban bee-killing pesticides", %{
    start: Date.add(Date.utc_today(), -120),

    # double opt-in: supporters must click the link in the confirm email
    supporter_confirm: true,
    supporter_confirm_template: "confirm_signature"
  })

pesticide_pages =
  [
    {create_page.(pesticides, bees, "petition/en", "en"), 20},
    {create_page.(pesticides, bees, "petition/de", "de"), 8}
  ] ++
    (partners
     |> Enum.take(5)
     |> Enum.map(fn {org, locale} -> {create_page.(pesticides, org, "bees", locale), 5} end))

# 4. Old closed campaign
plastic =
  create_campaign.(lead, "plastic-free-oceans", "Plastic-free oceans", %{
    status: :closed,
    start: Date.add(Date.utc_today(), -400),
    end: Date.add(Date.utc_today(), -250)
  })

plastic_pages = [{create_page.(plastic, lead, "plastic/en", "en"), 1}]

# ---------------------------------------------------------------------------
# Local email templates (rendered with Mustache on the server)
# ---------------------------------------------------------------------------

create_template = fn org_id, name, locale, subject, html ->
  Repo.insert!(
    %EmailTemplate{org_id: org_id, name: name, locale: locale, subject: subject, html: html},
    on_conflict: :nothing
  )
end

all_pages = Enum.map(fossil_pages ++ farm_pages ++ pesticide_pages ++ plastic_pages, &elem(&1, 0))

# a thank-you template for every org + language that has a page
for {org_id, locale} <- all_pages |> Enum.map(&{&1.org_id, &1.locale}) |> Enum.uniq() do
  create_template.(org_id, "thank_you", locale, "Thank you, {{firstName}}!", """
  <p>Hi {{firstName}},</p>
  <p>Thank you for taking action in <b>{{campaign.title}}</b>.</p>
  <p>Please share it with your friends: {{actionPage.url}}</p>
  """)
end

# double opt-in confirm email for the pesticides campaign
for {org_id, locale} <-
      pesticide_pages |> Enum.map(&{elem(&1, 0).org_id, elem(&1, 0).locale}) |> Enum.uniq() do
  create_template.(org_id, "confirm_signature", locale, "Please confirm your signature", """
  <p>Hi {{firstName}},</p>
  <p>One more step: <a href="{{confirmLink}}">confirm your signature</a> for {{campaign.title}}.</p>
  <p>Not you? <a href="{{rejectLink}}">Remove my data</a>.</p>
  """)
end

# MTT wrapper template for Farm to Fork: the supporter's message goes into {{{body}}}
for locale <- farm_pages |> Enum.map(&elem(&1, 0).locale) |> Enum.uniq() do
  create_template.(food.id, "mtt_farm", locale, "{{subject}}", """
  {{{body}}}
  <hr>
  <p style="color:#888">Sent by a citizen through the {{campaign.title}} campaign.</p>
  """)
end

Repo.update!(Ecto.Changeset.change(farm.mtt, message_template: "mtt_farm"))

# ---------------------------------------------------------------------------
# Sources (utm tracking)
# ---------------------------------------------------------------------------

sources =
  for {s, m, c, w} <- [
        {"facebook", "social", "launch", 30},
        {"newsletter", "email", "weekly", 25},
        {"twitter", "social", "launch", 8},
        {"whatsapp", "share", "supporter", 12},
        {"google", "cpc", "ads", 5},
        {"unknown", "unknown", "unknown", 20}
      ] do
    {Repo.insert!(%Source{
       source: s,
       medium: m,
       campaign: c <> suffix,
       content: "",
       location: "https://#{lead.domain}"
     }), w}
  end

# ---------------------------------------------------------------------------
# Message texts for MTT, per language
# ---------------------------------------------------------------------------

mtt_texts = %{
  "en" =>
    {"End fossil fuel subsidies now",
     "Dear {{target.name}},\n\nAs your constituent I ask you to vote to end all fossil fuel subsidies by 2027. Public money must go to clean energy.\n\nKind regards"},
  "fr" =>
    {"Mettez fin aux subventions aux énergies fossiles",
     "Madame, Monsieur {{target.name}},\n\nJe vous demande de voter pour la fin des subventions aux énergies fossiles.\n\nCordialement"},
  "de" =>
    {"Schluss mit Subventionen für fossile Energien",
     "Sehr geehrte/r {{target.name}},\n\nbitte stimmen Sie für das Ende der Subventionen für fossile Brennstoffe.\n\nMit freundlichen Grüßen"},
  "pl" =>
    {"Koniec z dotacjami do paliw kopalnych",
     "Szanowna Pani / Szanowny Panie {{target.name}},\n\nproszę o głosowanie za zakończeniem dotacji do paliw kopalnych.\n\nZ poważaniem"},
  "es" =>
    {"Fin a las subvenciones a los combustibles fósiles",
     "Estimado/a {{target.name}}:\n\nLe pido que vote para poner fin a las subvenciones a los combustibles fósiles.\n\nAtentamente"},
  "it" =>
    {"Basta sussidi ai combustibili fossili",
     "Gentile {{target.name}},\n\nLe chiedo di votare per eliminare i sussidi ai combustibili fossili.\n\nCordiali saluti"},
  "nl" =>
    {"Stop subsidies voor fossiele brandstoffen",
     "Geachte {{target.name}},\n\nIk vraag u te stemmen voor het einde van fossiele subsidies.\n\nMet vriendelijke groet"},
  "pt" =>
    {"Acabem com os subsídios aos combustíveis fósseis",
     "Caro/a {{target.name}},\n\nPeço-lhe que vote pelo fim dos subsídios aos combustíveis fósseis.\n\nCom os melhores cumprimentos"}
}

farm_texts = %{
  "en" =>
    {"Keep the Farm to Fork promises",
     "Dear Minister,\n\nPlease defend the pesticide reduction targets.\n\nRegards"},
  "fr" =>
    {"Tenez les promesses de la stratégie De la ferme à la table",
     "Madame la Ministre, Monsieur le Ministre,\n\nDéfendez les objectifs de réduction des pesticides.\n\nCordialement"},
  "it" =>
    {"Mantenete le promesse Farm to Fork",
     "Gentile Ministro,\n\ndifenda gli obiettivi di riduzione dei pesticidi.\n\nCordiali saluti"}
}

# ---------------------------------------------------------------------------
# Widget config (campaign.config) - what `proca campaign pull` fetches and the
# widget merges under each page's own config
# ---------------------------------------------------------------------------

# the widget adds the per-target salutation itself (email.salutation), so the
# letter it prefills starts after the greeting line
strip_greeting = fn body -> body |> String.split("\n\n", parts: 2) |> List.last() end

mtt_config = fn campaign, texts, extra_email ->
  %{
    "journey" => ["Email", "Share"],
    "component" => %{
      "email" =>
        Map.merge(
          %{
            "listUrl" => "#{target_list_base}/#{campaign.name}.json",
            "filter" => ["country"],
            "salutation" => true,
            "selectable" => true,
            "showTo" => true,
            "server" => true,
            "progress" => true
          },
          extra_email
        ),
      "register" => %{
        "actionType" => "email",
        "button" => "action.email",
        "field" => %{
          "firstname" => %{"required" => true},
          "lastname" => true,
          "email" => %{"required" => true},
          "country" => true,
          "postcode" => true,
          "comment" => false,
          "phone" => false,
          "organisation" => false
        }
      },
      "share" => %{"top" => true}
    },
    "locales" =>
      Map.new(texts, fn {locale, {subject, body}} ->
        {locale,
         %{
           "campaign:" => %{
             "title" => campaign.title,
             "description" => "",
             "email" => %{"subject" => subject, "body" => strip_greeting.(body)},
             "share" => %{"default" => "I emailed my representative, you should too"}
           },
           "common:" => %{"progress" => "{{count}} have sent an email. Let's go to {{goal}}"}
         }}
      end)
  }
end

petition_config = fn campaign, locales, extra ->
  %{
    "journey" => ["Petition", "Share"],
    "component" =>
      Map.merge(
        %{
          "register" => %{
            "field" => %{
              "firstname" => %{"required" => true},
              "lastname" => true,
              "email" => %{"required" => true},
              "country" => true,
              "postcode" => false,
              "comment" => true,
              "phone" => false
            }
          },
          "share" => %{"top" => true}
        },
        extra
      ),
    "locales" =>
      Map.new(locales, fn locale ->
        {locale, %{"campaign:" => %{"title" => campaign.title, "description" => ""}}}
      end)
  }
end

page_locales = fn pages -> pages |> Enum.map(&elem(&1, 0).locale) |> Enum.uniq() end

for {campaign, config} <- [
      {fossil, mtt_config.(fossil, mtt_texts, %{})},
      # only 2 ministers per country: show them all, preselected by country
      {farm, mtt_config.(farm, farm_texts, %{"selectable" => false})},
      {pesticides,
       petition_config.(pesticides, page_locales.(pesticide_pages), %{
         "counter" => %{"goal" => 250_000},
         "consent" => %{"email" => %{"confirmAction" => true}}
       })},
      {plastic, petition_config.(plastic, ["en"], %{"widget" => %{"closed" => true}})}
    ] do
  Repo.update!(Ecto.Changeset.change(campaign, config: config))
end

# ---------------------------------------------------------------------------
# Supporters and actions
# ---------------------------------------------------------------------------

supporter_status = [{:accepted, 88}, {:confirming, 5}, {:new, 3}, {:rejected, 4}]
# with double opt-in many never click the confirm link
doi_status = [{:accepted, 72}, {:confirming, 22}, {:new, 2}, {:rejected, 4}]

action_status_for = %{
  accepted: :delivered,
  confirming: :confirming,
  new: :new,
  rejected: :rejected
}

# earlier supporters per campaign, to create some duplicate signatures
seen = :ets.new(:seen, [:bag])
empty_left = :counters.new(1, [])
:counters.put(empty_left, 1, empty_content_count)

create_supporter = fn page, inserted_at, statuses ->
  locale = page.locale
  %{country: cc, postcode: pc} = Map.get(countries, locale, countries["en"])

  earlier = :ets.lookup(seen, page.campaign_id)

  data =
    if earlier != [] and :rand.uniform() < 0.04 do
      # same person signing again, possibly on another partner's page
      {_, data} = Enum.random(earlier)
      data
    else
      first = Faker.Person.first_name()
      last = Faker.Person.last_name()
      n = System.unique_integer([:positive])
      slug = "#{first}.#{last}" |> String.downcase() |> String.replace(~r/[^a-z.]/, "")

      data = %BasicData{
        first_name: first,
        last_name: last,
        email: "#{slug}.#{n}@example.#{Enum.random(["org", "com", "net"])}",
        country: cc,
        postcode: pc.()
      }

      :ets.insert(seen, {page.campaign_id, data})
      data
    end

  privacy = %Supporter.Privacy{opt_in: :rand.uniform() < 0.6, lead_opt_in: :rand.uniform() < 0.4}
  status = weighted.(statuses)
  doi? = page.campaign.supporter_confirm == true

  supporter =
    Supporter.new_supporter(data, page)
    |> Supporter.add_contacts(Proca.Contact.Data.to_contact(data, page), page, privacy)
    |> Ecto.Changeset.change(
      processing_status: status,
      email_status:
        cond do
          :rand.uniform() < 0.02 -> :bounce
          doi? and status == :accepted -> :double_opt_in
          true -> :none
        end,
      source_id: weighted.(sources).id,
      inserted_at: inserted_at,
      updated_at: inserted_at
    )
    |> Repo.insert!()

  {supporter, status, privacy}
end

create_action = fn supporter, page, type, status, inserted_at, attrs ->
  Repo.insert!(
    struct(
      %Action{
        action_type: type,
        supporter_id: supporter.id,
        campaign_id: page.campaign_id,
        action_page_id: page.id,
        source_id: supporter.source_id,
        processing_status: status,
        inserted_at: inserted_at,
        updated_at: inserted_at
      },
      attrs
    )
  )
end

create_mtt_action = fn supporter, page, status, privacy, inserted_at, targets, texts, drip? ->
  action =
    create_action.(supporter, page, "mtt", status, inserted_at, %{with_consent: privacy.opt_in})

  {subject, body} = Map.get(texts, page.locale, texts["en"])

  # some supporters rewrite the message, some leave an empty subject
  {subject, body} =
    cond do
      :counters.get(empty_left, 1) > 0 and status == :delivered ->
        :counters.sub(empty_left, 1, 1)
        {"", body}

      :rand.uniform() < 0.15 ->
        {subject <> "!", body <> "\n\nP.S. " <> Faker.Lorem.sentence()}

      true ->
        {subject, body}
    end

  content = Repo.insert!(%MessageContent{subject: subject, body: body})

  cc = Map.get(countries, page.locale, countries["en"]).country
  local = Enum.filter(targets, &(&1.area == cc))
  chosen = Enum.take_random(if(local == [], do: targets, else: local), Enum.random(1..3))

  age_days = NaiveDateTime.diff(now, inserted_at) / 86_400

  for t <- chosen do
    # drip sends spread messages over days; non-drip sends right away
    sent =
      status == :delivered and subject != "" and
        ((drip? and age_days > 3) or (not drip? and age_days > 0.05))

    # sent to a dead address: the provider accepted it, the delivery bounced
    dead? = Enum.all?(t.emails, &(&1.email_status == :bounce))
    delivered = sent and not dead? and :rand.uniform() < 0.97
    opened = delivered and :rand.uniform() < 0.4
    clicked = opened and :rand.uniform() < 0.1

    Repo.insert!(%Message{
      action_id: action.id,
      target_id: t.id,
      message_content_id: content.id,
      sent: sent,
      delivered: delivered,
      opened: opened,
      clicked: clicked,
      updated_at: inserted_at
    })
  end

  action
end

campaign_plan = [
  {:fossil, fossil, fossil_pages, 0.45},
  {:farm, farm, farm_pages, 0.15},
  {:pesticides, pesticides, pesticide_pages, 0.30},
  {:plastic, plastic, plastic_pages, 0.10}
]

for {kind, campaign, pages, share} <- campaign_plan do
  count = round(total_supporters * share)
  campaign_start = NaiveDateTime.new!(campaign.start, ~T[08:00:00])

  campaign_end =
    case Map.get(campaign, :end) do
      %Date{} = d ->
        if Date.compare(d, Date.utc_today()) == :lt,
          do: NaiveDateTime.new!(d, ~T[20:00:00]),
          else: now

      nil ->
        now
    end

  IO.write("  #{campaign.name}: #{count} supporters ")

  for i <- 1..count do
    page = weighted.(pages)

    inserted_at =
      random_time_since.(campaign_start)
      |> then(&if NaiveDateTime.compare(&1, campaign_end) == :gt, do: campaign_end, else: &1)

    statuses = if campaign.supporter_confirm, do: doi_status, else: supporter_status
    {supporter, status, privacy} = create_supporter.(page, inserted_at, statuses)
    action_status = action_status_for[status]

    case kind do
      :fossil ->
        create_mtt_action.(
          supporter,
          page,
          action_status,
          privacy,
          inserted_at,
          fossil_targets,
          mtt_texts,
          true
        )

      :farm ->
        create_mtt_action.(
          supporter,
          page,
          action_status,
          privacy,
          inserted_at,
          farm_targets,
          farm_texts,
          false
        )

      :pesticides ->
        create_action.(supporter, page, "petition", action_status, inserted_at, %{
          with_consent: privacy.opt_in,
          fields: %{"comment" => if(:rand.uniform() < 0.2, do: Faker.Lorem.sentence(), else: "")}
        })

        if :rand.uniform() < 0.35 do
          create_action.(
            supporter,
            page,
            "share",
            action_status,
            NaiveDateTime.add(inserted_at, 40),
            %{
              fields: %{
                "medium" => Enum.random(["whatsapp", "facebook", "twitter", "email", "telegram"])
              }
            }
          )
        end

        if :rand.uniform() < 0.06 do
          action =
            create_action.(
              supporter,
              page,
              "donate",
              action_status,
              NaiveDateTime.add(inserted_at, 90),
              %{}
            )

          Repo.insert!(%Donation{
            action_id: action.id,
            amount: Enum.random([500, 1000, 1000, 2000, 2500, 5000, 10_000]),
            currency: "EUR",
            frequency_unit: weighted.([{:one_off, 70}, {:monthly, 30}]),
            inserted_at: inserted_at,
            updated_at: inserted_at
          })
        end

      :plastic ->
        create_action.(supporter, page, "petition", action_status, inserted_at, %{
          with_consent: privacy.opt_in
        })
    end

    if rem(i, 250) == 0, do: IO.write(".")
  end

  IO.puts(" done")
end

# A few test actions (sent from the campaign's MTT test flow)
fossil_en = fossil_pages |> hd() |> elem(0)

for _ <- 1..5 do
  {supporter, _, privacy} = create_supporter.(fossil_en, days_ago.(1), [{:accepted, 1}])

  create_mtt_action.(
    supporter,
    fossil_en,
    :delivered,
    privacy,
    days_ago.(1),
    fossil_targets,
    mtt_texts,
    true
  )
  |> Ecto.Changeset.change(testing: true)
  |> Repo.update!()
end

# ---------------------------------------------------------------------------
# Duplicate ranks, like the processing pipeline and MTT server compute them
# ---------------------------------------------------------------------------

Repo.query!("""
UPDATE supporters s SET dupe_rank = r.rank
FROM (
  SELECT id, rank() OVER (PARTITION BY fingerprint, campaign_id ORDER BY id) - 1 AS rank
  FROM supporters WHERE processing_status = #{SupporterProcessingStatus.__enum_map__()[:accepted]}
) r
WHERE s.id = r.id AND s.dupe_rank IS NULL
""")

Proca.Server.MTTContext.dupe_rank()

:ets.delete(seen)

IO.puts("""

Done.
  Staff users: owner@<org>.example.org and campaigner@<org>.example.org
  Password:    #{password}
  e.g.         owner@#{lead.domain}
#{if admin, do: "  #{admin.email} is owner of #{lead.name}, #{food.name}, #{bees.name}", else: ""}
  Webhook push backend: #{rivers.name}, detail backend: #{umwelt.name}
""")

# Append logins and ids to credentials.md (gitignored) so they are not lost
# in the terminal scrollback.
all_orgs = [lead, food, bees] ++ Enum.map(partners, &elem(&1, 0))

page_rows = fn pages ->
  Enum.map_join(pages, "\n", fn {p, _} -> "  - page #{p.id}: #{p.name} (#{p.locale})" end)
end

File.write!(
  "credentials.md",
  """

  ## Realistic seed#{if suffix != "", do: " (tag #{opts[:tag]})", else: ""} (#{DateTime.utc_now() |> DateTime.truncate(:second)})

  Password for all staff users: `#{password}`
  #{if admin, do: "\n#{admin.email} is owner of #{lead.name}, #{food.name}, #{bees.name}\n", else: ""}
  | Org | Owner | Campaigner |
  |---|---|---|
  #{Enum.map_join(all_orgs, "\n", fn o -> "| #{o.name} (#{o.id}) | owner@#{o.domain} | campaigner@#{o.domain} |" end)}

  Campaigns and pages:

  - #{fossil.name} (campaign #{fossil.id}) - MTT, drip, targets: #{target_list_base}/#{fossil.name}.json
  #{page_rows.(fossil_pages)}
  - #{farm.name} (campaign #{farm.id}) - MTT, no drip, targets: #{target_list_base}/#{farm.name}.json
  #{page_rows.(farm_pages)}
  - #{pesticides.name} (campaign #{pesticides.id}) - petition, double opt-in
  #{page_rows.(pesticide_pages)}
  - #{plastic.name} (campaign #{plastic.id}) - petition, closed
  #{page_rows.(plastic_pages)}
  """,
  [:append]
)

IO.puts("Logins and ids saved to credentials.md")
