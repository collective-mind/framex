defmodule Mix.Tasks.Framex.Corpus.Fetch do
  use Mix.Task

  @shortdoc "Fetches a verified FrameNet corpus into priv/corpora"

  def run(arguments) do
    {switches, positionals, invalid} =
      arguments
      |> normalize_flags()
      |> OptionParser.parse(strict: [corpus_profile: :string, corpus_full: :boolean])

    with [] <- positionals,
         [] <- invalid,
         {:ok, mode} <- fetch_mode(switches),
         {:ok, source} <- fetch_with_tools(mode) do
      report_opened_corpus(source)
    else
      {:error, :tools_required} -> Mix.raise(tools_required_message())
      _reason -> Mix.raise(usage())
    end
  end

  defp fetch_mode(switches) do
    full? = Keyword.get(switches, :corpus_full, false)
    profile = Keyword.get(switches, :corpus_profile)
    choose_mode(full?, profile)
  end

  defp choose_mode(true, nil), do: {:ok, :full}
  defp choose_mode(false, profile), do: profile_mode(profile)
  defp choose_mode(_full?, _profile), do: {:error, :invalid_mode}

  defp profile_mode(nil), do: {:ok, {:profile, nil}}
  defp profile_mode(name), do: {:ok, {:profile, name}}

  defp fetch_with_tools(:full) do
    call_tools(fn -> apply(FramexTools.Fetch, :full, []) end)
  end

  defp fetch_with_tools({:profile, nil}) do
    with {:ok, name} <- default_profile_name() do
      fetch_with_tools({:profile, name})
    end
  end

  defp fetch_with_tools({:profile, name}) do
    with {:ok, profile_name} <- profile_name(name) do
      call_tools(fn -> apply(FramexTools.Fetch, :run, [profile_name]) end)
    end
  end

  defp default_profile_name do
    case Code.ensure_loaded(FramexTools) do
      {:module, _module} -> {:ok, apply(FramexTools, :default_corpus_profile, [])}
      {:error, _reason} -> {:error, :tools_required}
    end
  end

  defp profile_name(name) when is_binary(name) do
    case Code.ensure_loaded(FramexTools) do
      {:module, _module} -> resolve_profile_name(name)
      {:error, _reason} -> {:error, :tools_required}
    end
  end

  defp resolve_profile_name(name) do
    case apply(FramexTools, :profile_by_name, [name]) do
      {:ok, _profile} -> {:ok, String.to_existing_atom(name)}
      :error -> {:error, :unknown_corpus_profile}
    end
  end

  defp call_tools(fetcher) do
    case Code.ensure_loaded(FramexTools.Fetch) do
      {:module, _module} -> run_with_progress(fetcher)
      {:error, _reason} -> {:error, :tools_required}
    end
  end

  defp run_with_progress(fetcher) do
    Mix.shell().info("Downloading corpus")
    progress = spawn(fn -> progress_loop(0) end)
    result = fetcher.()
    send(progress, :done)
    result
  end

  defp progress_loop(index) do
    frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
    frame = Enum.at(frames, rem(index, length(frames)))

    receive do
      :done -> IO.puts("\rCorpus downloaded.                 ")
    after
      120 ->
        IO.write("\rDownloading corpus #{frame}")
        progress_loop(index + 1)
    end
  end

  defp report_opened_corpus(source) do
    Mix.shell().info("Extracting files into priv/corpora")

    with {:ok, _corpus} <- Framex.open(source) do
      Mix.shell().info("Corpus ready")
      Mix.shell().info("Path: #{source}")
      {:ok, source}
    else
      {:error, reason} -> {:error, {:corpus_open_failed, reason}}
    end
  end

  defp normalize_flags(arguments) do
    Enum.map(arguments, fn argument ->
      case argument do
        "--corpus_profile" -> "--corpus-profile"
        "--corpus_full" -> "--corpus-full"
        "--full" -> "--corpus-full"
        other_argument -> other_argument
      end
    end)
  end

  defp tools_required_message do
    "mix framex.corpus.fetch requires framex_tools; add {:framex_tools, git: \"https://github.com/collective-mind/framex-tools.git\"}"
  end

  defp usage do
    "usage: mix framex.corpus.fetch [--corpus_profile NAME | --corpus_full | --full]"
  end
end
