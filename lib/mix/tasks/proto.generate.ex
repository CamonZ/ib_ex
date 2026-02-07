defmodule Mix.Tasks.Proto.Generate do
  @moduledoc """
  Generates Elixir modules from protobuf definitions.

  Runs `protoc` with the `protoc-gen-elixir` plugin to compile all `.proto`
  files in `priv/proto/` into Elixir modules under `lib/ib_ex/client/proto/`.

  ## Prerequisites

    * `protoc` (Protocol Buffers compiler) must be installed.
      Install via Homebrew: `brew install protobuf`

    * `protoc-gen-elixir` (Elixir protoc plugin) must be installed.
      Install via: `mix escript.install hex protobuf`

  ## Usage

      mix proto.generate

  """

  use Mix.Task

  @shortdoc "Generate Elixir modules from .proto files"

  @proto_source_dir "priv/proto"
  @output_dir "lib/ib_ex/client/proto"
  @package_prefix "ib_ex.client.proto"

  @impl Mix.Task
  def run(_args) do
    with :ok <- check_protoc(),
         :ok <- check_protoc_gen_elixir(),
         :ok <- check_proto_files() do
      generate()
    end
  end

  defp check_protoc do
    case System.find_executable("protoc") do
      nil ->
        Mix.shell().error("""
        Error: protoc is not installed.

        protoc (Protocol Buffers compiler) is required to generate Elixir modules from .proto files.

        Installation instructions:
          macOS:   brew install protobuf
          Ubuntu:  apt-get install -y protobuf-compiler
          Other:   https://github.com/protocolbuffers/protobuf/releases
        """)

        exit({:shutdown, 1})

      _path ->
        :ok
    end
  end

  defp check_protoc_gen_elixir do
    case System.find_executable("protoc-gen-elixir") do
      nil ->
        escript_dir = Path.join([Mix.path_for(:escripts), "protoc-gen-elixir"])

        if File.exists?(escript_dir) do
          :ok
        else
          Mix.shell().error("""
          Error: protoc-gen-elixir is not installed.

          The Elixir protoc plugin is required to generate Elixir modules from .proto files.

          Install it with:
            mix escript.install hex protobuf

          Then ensure ~/.mix/escripts is in your PATH, or if using asdf, run:
            asdf reshim elixir
          """)

          exit({:shutdown, 1})
        end

      _path ->
        :ok
    end
  end

  defp check_proto_files do
    proto_dir = Path.join(File.cwd!(), @proto_source_dir)

    if File.dir?(proto_dir) do
      proto_files = Path.wildcard(Path.join(proto_dir, "*.proto"))

      if Enum.empty?(proto_files) do
        Mix.shell().error("Error: No .proto files found in #{@proto_source_dir}/")
        exit({:shutdown, 1})
      else
        :ok
      end
    else
      Mix.shell().error("Error: Proto source directory #{@proto_source_dir}/ does not exist.")
      exit({:shutdown, 1})
    end
  end

  defp generate do
    output_dir = Path.join(File.cwd!(), @output_dir)
    proto_source_dir = Path.join(File.cwd!(), @proto_source_dir)

    File.mkdir_p!(output_dir)

    # Clean previously generated files
    output_dir
    |> Path.join("*.pb.ex")
    |> Path.wildcard()
    |> Enum.each(&File.rm!/1)

    proto_files =
      proto_source_dir
      |> Path.join("*.proto")
      |> Path.wildcard()
      |> Enum.map(&Path.relative_to_cwd/1)

    Mix.shell().info("Generating Elixir modules from #{length(proto_files)} proto files...")

    # Build the PATH to include the escripts directory
    escript_dir = Mix.path_for(:escripts)
    current_path = System.get_env("PATH", "")
    env = [{"PATH", "#{escript_dir}:#{current_path}"}]

    args =
      [
        "--elixir_out=#{output_dir}",
        "--elixir_opt=package_prefix=#{@package_prefix}",
        "--proto_path=#{@proto_source_dir}"
      ] ++ proto_files

    case System.cmd("protoc", args, env: env, stderr_to_stdout: true) do
      {_output, 0} ->
        generated_files =
          output_dir
          |> Path.join("*.pb.ex")
          |> Path.wildcard()

        format_generated_files(generated_files)

        Mix.shell().info("Converting field names to snake_case...")
        Enum.each(generated_files, &snake_case_fields/1)

        format_generated_files(generated_files)

        Mix.shell().info("Generated #{length(generated_files)} Elixir modules in #{@output_dir}/")

      {output, exit_code} ->
        Mix.shell().error("protoc failed (exit code #{exit_code}):\n#{output}")
        exit({:shutdown, exit_code})
    end
  end

  defp format_generated_files(files) do
    Mix.shell().info("Formatting generated files...")
    Mix.Tasks.Format.run(Enum.map(files, &Path.relative_to_cwd/1))
  end

  defp snake_case_fields(file_path) do
    content = File.read!(file_path)

    updated =
      Regex.replace(~r/field\(:(\w+), (\d+),/, content, fn _match, field_name, field_number ->
        snake_name = Macro.underscore(field_name)

        if snake_name == field_name do
          "field(:#{field_name}, #{field_number},"
        else
          "field(:#{snake_name}, #{field_number}, json_name: \"#{field_name}\","
        end
      end)

    File.write!(file_path, updated)
  end
end
