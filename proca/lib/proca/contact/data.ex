defprotocol Proca.Contact.Data do
    @moduledoc """
    Defines different styles of personal data that are stored in Contact.
    """

    @doc """
    Accepts (virtual) data changeset, and action page. Returns contact changeset and fingerprint
    """
    @spec to_contact(t, ActionPage.t) :: Changeset.t(Contact)
    def to_contact(data, action_page)

    @spec fingerprint(t) :: binary()
    def fingerprint(t)
end
