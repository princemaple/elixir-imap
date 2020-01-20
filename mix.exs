defmodule Imap.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :imap,
      version: @version,
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      description: "A simple library to interact with an IMAP server",

      # Docs
      name: "Imap",
      source_url: "https://github.com/around25/imap",
      homepage_url: "https://pochen.me",
      preferred_cli_env: [coveralls: :test],
      docs: docs()
    ]
  end

  defp package do
    [
      name: "imap",
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Po Chen <chenpaul914@gmail.com>"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/princemaple/imap"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:mail, path: "../elixir-mail"}]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end
end
