defmodule Blop.Mailbox do
  @moduledoc """
  Message flags:

  (RFC 3501)
  - \\Seen - Message has been read
  - \\Answered - Message has been replied to
  - \\Flagged - Message is marked as important or flagged for attention
  - \\Deleted - Message is marked for deletion
  - \\Draft - Message is a draft
  - \\Recent - Message is new in the mailbox since last access

  Mailbox flags:

  (RFC 3501)
  - \\Noinferiors - Mailbox cannot have child mailboxes
  - \\Noselect - Mailbox cannot be selected (often used for namespace containers)
  - \\Marked - Mailbox contains new messages
  - \\Unmarked - Mailbox has no new messages

  (RFC 3348)
  - \\HasChildren - Mailbox has child mailboxes
  - \\HasNoChildren - Mailbox has no child mailboxes

  Special-use mailbox attributes (RFC 6154):

  - \\All - Contains all messages
  - \\Archive - Used for archiving messages
  - \\Drafts - Contains draft messages
  - \\Flagged - Contains flagged messages
  - \\Junk - Contains spam/junk messages
  - \\Sent - Contains sent messages
  - \\Trash - Contains deleted messages
  - \\Important - Contains important messages
  """

  defstruct [:name, :delimiter, :flags, :exists, :recent]

  def decode_name(mailbox) do
    Blop.UTF7.decode(mailbox.name)
  end

  def find(mailbox_name) do
    Access.find(fn %{name: name} -> name == mailbox_name end)
  end
end

defimpl Inspect, for: Blop.Mailbox do
  import Inspect.Algebra

  def inspect(mailbox, opts) do
    concat([
      "#Blop.Mailbox<",
      to_doc(Blop.Mailbox.decode_name(mailbox), opts),
      " (",
      to_doc(mailbox.delimiter, opts),
      ") ",
      to_doc(mailbox.flags, opts),
      " ",
      if(mailbox.exists, do: "#{mailbox.exists}", else: "TBD"),
      ">"
    ])
  end
end
