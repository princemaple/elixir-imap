# IMAP

IMAP Client for Elixir

## Installation

```elixir
def deps do
  [
    {:imap, "~> 0.1"}
  ]
end
```

## Usage

```elixir
alias Imap.Client

{:ok, client} = Client.new(
  host: "imap.my.host",
  port: 993,
  login: {"me@my.host", "my_strong_password"}
)

Client.list(client)

Client.select(client, "INBOX")

Client.fetch(client, "1:5")
```
