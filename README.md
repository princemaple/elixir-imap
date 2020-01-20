# UNDER REWRITE

```
.....
```

## Development

In order to test and develop the library locally you will need an IMAP server.
One easy way of getting an IMAP server up and running is with Docker.

Make sure you have Docker installed and that the following ports are open and then run this command:
```sh
docker run -d -p 25:25 -p 80:80 -p 443:443 -p 110:110 -p 143:143 -p 465:465 -p 587:587 -p 993:993 -p 995:995 -v /etc/localtime:/etc/localtime:ro -t analogic/poste.io
curl --insecure --request POST --url https://localhost/admin/install/server --form install[hostname]=127.0.0.1 --form install[superAdmin]=admin@127.0.0.1 --form install[superAdminPassword]=admin
```

Once the container is up and running you can create a new email address.
The credentials used in testing this library are:
Host: localhost.dev
Port: 993
User: admin@localhost.dev
Pass: secret

You can run the tests using:
```
mix deps.get
mix test
```

## Usage

```
......
```

## Installation

Eximap in [available in Hex](https://hex.pm/docs/publish) and can be installed
by adding `imap` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:imap, "~> 0.1"}
  ]
end
```

The documentation is available here: https://hexdocs.pm/imap/readme.html
