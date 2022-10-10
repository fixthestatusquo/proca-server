import Proca.Repo
alias Proca.Users.User

alias Proca.{
  ActionPage,
  Campaign,
  Consent,
  Contact,
  SupporterContact,
  Supporter,
  Action,
  Field,
  Source,
  Service,
  Confirm
}

alias Proca.{Org, Staffer, PublicKey}
alias Proca.Server.{Encrypt, Notify, Stat}
import Ecto.Query, only: [from: 2]
import Ecto.Changeset

IEx.configure(
  colors: [
    syntax_colors: [
      number: :magenta,
      atom: :cyan,
      string: :green,
      boolean: :magenta,
      nil: :magenta
    ]
  ]
)
