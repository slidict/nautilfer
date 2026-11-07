# frozen_string_literal: true

require "yaml"

RSpec.describe "Ruby version requirement" do
  # The gemspec is the only one of these that decides whether an install succeeds,
  # so everything else that names a supported Ruby has to agree with it. They
  # drifted once already: the floor moved to 4.0 and the README kept 3.4, which an
  # installer would have hit and a reader would not.
  let(:root) { File.expand_path("..", __dir__) }
  let(:gemspec) { Gem::Specification.load(File.join(root, "nautilfer.gemspec")) }
  let(:requirement) { gemspec.required_ruby_version }
  let(:floor) { requirement.requirements.first.last }

  it "accepts Ruby 4.0 and rejects Ruby 3.4" do
    # Literal versions on purpose: this is the support decision itself, so moving
    # the floor should fail here and be re-decided rather than quietly follow.
    expect(requirement.satisfied_by?(Gem::Version.new("4.0.0"))).to be(true)
    expect(requirement.satisfied_by?(Gem::Version.new("3.4.12"))).to be(false)
  end

  it "is satisfied by every Ruby the CI matrix tests" do
    # The job is named after the matrix entry, so these names are also the required
    # status checks. Testing a Ruby the gem does not support, or claiming support
    # for one never tested, are both caught here.
    matrix = YAML.safe_load_file(File.join(root, ".github/workflows/main.yml"))
                 .dig("jobs", "build", "strategy", "matrix", "ruby")

    expect(matrix).not_to be_nil, "jobs.build.strategy.matrix.ruby is missing from .github/workflows/main.yml"
    expect(matrix).not_to be_empty
    matrix.each do |version|
      accepted = requirement.satisfied_by?(Gem::Version.new(version.to_s))
      expect(accepted).to be(true), "CI tests Ruby #{version}, which #{requirement} rejects"
    end
  end

  it "is the requirement the README documents" do
    documented = File.read(File.join(root, "README.md"))[/^- Ruby (.+)$/, 1]

    expect(documented).not_to be_nil, "README.md has no '- Ruby <requirement>' line under Requirements"
    expect(Gem::Requirement.new(documented.strip)).to eq(requirement)
  end

  it "is the version RuboCop targets" do
    # Gemspec/RequiredRubyVersion reports this mismatch, but RuboCop does not run
    # in CI, so nothing would otherwise notice it.
    target = YAML.safe_load_file(File.join(root, ".rubocop.yml")).dig("AllCops", "TargetRubyVersion")

    expect(target).not_to be_nil, ".rubocop.yml has no AllCops.TargetRubyVersion"
    expect(target.to_s).to eq(floor.to_s)
  end
end
