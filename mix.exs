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
      source_url: "https://github.com/princemaple/elixir-imap",
      homepage_url: "https://pochen.me",
      docs: docs()
    ]
  end

  defp package do
    [
      name: "imap",
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Po Chen <chenpaul914@gmail.com>"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/princemaple/elixir-imap"}
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:mail, path: "../elixir-mail"},
      {:abnf_parsec, "~> 1.0"}
    ]
  end

  defp docs do
    [main: "readme", extras: ["README.md"]]
  end
end
