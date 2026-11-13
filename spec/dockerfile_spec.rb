# frozen_string_literal: true

require "yaml"

RSpec.describe "Dockerfile" do
  subject(:lines) { File.readlines(dockerfile).map(&:strip) }

  # Paths resolve from this file, not from the process working directory, so the
  # suite passes from a subdirectory as well as from the repository root.
  let(:dockerfile) { File.expand_path("../Dockerfile", __dir__) }
  let(:workflow) { File.expand_path("../.github/workflows/main.yml", __dir__) }

  let(:from_lines) { lines.grep(/\AFROM\s/i) }
  # A stage named with AS is referred to by that name in a later FROM. Such a line
  # names no registry image, so it is not one of the images to check.
  let(:stage_aliases) { from_lines.filter_map { |line| line[/\sAS\s+(\S+)\s*\z/i, 1]&.downcase } }
  # FROM accepts flags such as --platform= before the image, so the image is not
  # always the first token. Drop the flags, then take the image and ignore any AS.
  let(:images) do
    from_lines.filter_map { |line|
      line.sub(/\AFROM\s+/i, "").split(/\s+/).reject { |token| token.start_with?("--") }.first
    }.reject { |image| stage_aliases.include?(image.downcase) }
  end

  it "names only images that pull without registry credentials" do
    # Every stage, not only the first: a later stage of a multi-stage build could
    # reintroduce a credential-gated base while the first line still reads as an
    # official library image. The suite is matched against a known set so that a
    # typo such as ruby:3.4-bookwrom fails here, since the tag is only text to this
    # spec and no job builds the image. A well-formed tag that does not exist is
    # still not caught; proving the pull needs a build, which CI does not run.
    expect(images).not_to be_empty
    images.each do |image|
      expect(image).to match(/\Aruby:\d+\.\d+(\.\d+)?(-slim)?-(bookworm|trixie)\z/)
    end
  end

  it "tracks a Ruby version the CI matrix tests" do
    # Membership, not equality: the matrix may hold more than one entry, so no
    # single FROM line could contain all of them.
    matrix = YAML.safe_load_file(workflow).dig("jobs", "build", "strategy", "matrix", "ruby")

    expect(matrix).not_to be_nil, "jobs.build.strategy.matrix.ruby is missing from #{workflow}"

    # The last stage is the one that runs, so that is the version to check. Reading
    # the first stage instead would let a multi-stage build pass on its builder image
    # while shipping a runtime the gemspec rejects.
    runtime = images.last
    expect(runtime).not_to be_nil, "no registry image is named in #{dockerfile}"

    version = runtime[/\Aruby:(\d+\.\d+)/, 1]
    expect(version).not_to be_nil, "the last stage #{runtime.inspect} is not a ruby:<major>.<minor> image"
    expect(matrix.map(&:to_s)).to include(version)
  end

  it "sets the working directory before copying the project in" do
    # The official ruby image sets no WORKDIR. Without one, COPY would place the
    # project in / and bundle install would run there. Matched as patterns rather
    # than exact strings so that equivalent spellings still pass.
    workdir = lines.index { |line| line.match?(%r{\AWORKDIR\s+/app/?\z}i) }
    copy = lines.index { |line| line.match?(%r{\ACOPY\s+\.(/)?\s+(\.(/)?|/app/?)\z}i) }

    expect(workdir).not_to be_nil
    expect(copy).not_to be_nil
    expect(workdir).to be < copy
  end
end
