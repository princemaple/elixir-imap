alias Imap.{Client, Request, Response, Parser, Socket}

client = with true <- File.exists?("secrets.json") do
  secrets = File.read!("secrets.json") |> JSON.decode!()

  {:ok, client} = Client.new(
    host: secrets["host"],
    ssl: [verify: :verify_none],
    login: {secrets["username"], secrets["password"]}
  )

  Client.list(client, ~s|""|, "*")

  Client.select(client, "INBOX")

  client
end

