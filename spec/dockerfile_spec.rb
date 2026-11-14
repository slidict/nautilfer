# frozen_string_literal: true

require "yaml"

# Reads the FROM lines of a Dockerfile and answers which images it uses.
#
# Two things make that more than reading the first token. FROM accepts flags such
# as --platform= before the image, so the image is not always the first word. And a
# stage named with AS can be referred to by that name in a later FROM, so such a
# line names no registry image at all.
class DockerfileStages
  def initialize(lines)
    @from_lines = lines.grep(/\AFROM\s/i)
  end

  # Only the images actually pulled from a registry. Lines that refer to an earlier
  # stage by its alias are left out, because they pull nothing.
  def registry_images
    targets.reject { |target| aliases.key?(target.downcase) }
  end

  # The last stage is the one that runs. It may refer to an earlier stage by alias,
  # so follow the aliases to the image that stage was built from.
  def runtime_image
    resolve(targets.last)
  end

  private

  def targets
    @targets ||= @from_lines.filter_map { |line| image_token(line) }
  end

  def aliases
    @aliases ||= @from_lines.each_with_object({}) do |line, map|
      name = line[/\sAS\s+(\S+)\s*\z/i, 1]
      map[name.downcase] = image_token(line) if name
    end
  end

  def image_token(line)
    line.sub(/\AFROM\s+/i, "").split(/\s+/).reject { |token| token.start_with?("--") }.first
  end

  # An alias can point at another alias. Stop on a cycle rather than recurse forever.
  def resolve(target, seen = [])
    key = target.to_s.downcase
    return target unless aliases.key?(key)
    return nil if seen.include?(key)

    resolve(aliases[key], seen + [key])
  end
end

RSpec.describe "Dockerfile" do
  subject(:lines) { File.readlines(dockerfile).map(&:strip) }

  # Paths resolve from this file, not from the process working directory, so the
  # suite passes from a subdirectory as well as from the repository root.
  let(:dockerfile) { File.expand_path("../Dockerfile", __dir__) }
  let(:workflow) { File.expand_path("../.github/workflows/main.yml", __dir__) }
  let(:stages) { DockerfileStages.new(lines) }

  it "names only images that pull without registry credentials" do
    # Every stage, not only the first: a later stage could reintroduce a
    # credential-gated base while the first line still reads as an official image.
    # A well-formed tag that does not exist is still not caught; proving the pull
    # needs a build, which CI does not run.
    images = stages.registry_images

    expect(images).not_to be_empty
    images.each { |image| expect(image).to match(/\Aruby:\d+\.\d+(\.\d+)?(-slim)?-(bookworm|trixie)\z/) }
  end

  it "tracks a Ruby version the CI matrix tests" do
    # Membership, not equality: the matrix may hold more than one entry.
    matrix = YAML.safe_load_file(workflow).dig("jobs", "build", "strategy", "matrix", "ruby")
    expect(matrix).not_to be_nil, "jobs.build.strategy.matrix.ruby is missing from #{workflow}"

    runtime = stages.runtime_image
    expect(runtime).not_to be_nil, "the last FROM in #{dockerfile} resolves to no image"

    version = runtime[/\Aruby:(\d+\.\d+)/, 1]
    expect(version).not_to be_nil, "the last stage #{runtime.inspect} is not a ruby:<major>.<minor> image"
    expect(matrix.map(&:to_s)).to include(version)
  end

  it "sets the working directory before copying the project in" do
    # The official ruby image sets no WORKDIR. Without one, COPY would place the
    # project in / and bundle install would run there.
    workdir = lines.index { |line| line.match?(%r{\AWORKDIR\s+/app/?\z}i) }
    copy = lines.index { |line| line.match?(%r{\ACOPY\s+\.(/)?\s+(\.(/)?|/app/?)\z}i) }

    expect(workdir).not_to be_nil
    expect(copy).not_to be_nil
    expect(workdir).to be < copy
  end
end
