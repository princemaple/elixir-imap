defmodule Imap.Mailbox do
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

  defstruct name: nil, scope: "/", flags: [], exists: 0, recent: 0
end
