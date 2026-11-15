# frozen_string_literal: true

require "yaml"

RSpec.describe "CI workflow triggers" do
  # A wrong push filter is invisible: the build stays green either way, and the only
  # thing lost is a run on the default branch that never appears. It named `master`
  # on a repository whose default branch is `main`, so no push run ever fired.
  let(:workflow) { File.expand_path("../.github/workflows/main.yml", __dir__) }

  # YAML 1.1 reads the bare key `on` as the boolean true, not the string "on". A
  # lookup by "on" returns nil, so the checks below would pass or fail for the wrong
  # reason.
  let(:triggers) { YAML.safe_load_file(workflow)[true] }

  it "runs on pushes to main" do
    # A literal on purpose: this is the decision itself, so changing the default
    # branch should fail here and be re-decided rather than quietly followed.
    expect(triggers).not_to be_nil, "#{workflow} has no `on:` section"
    expect(triggers.dig("push", "branches")).to eq(["main"]),
                                                "#{workflow} does not limit push runs to main"
  end

  it "still runs on pull requests" do
    # This is the trigger that has always worked. Narrowing or dropping it is the
    # mistake next to this fix.
    expect(triggers).not_to be_nil, "#{workflow} has no `on:` section"
    expect(triggers).to have_key("pull_request"), "#{workflow} no longer runs on pull_request"
  end
end
