# frozen_string_literal: true

require_relative "lib/nautilfer/version"

Gem::Specification.new do |spec|
  spec.name          = "nautilfer"
  spec.version       = Nautilfer::VERSION
  spec.authors       = ["Yusuke Abe"]
  spec.email         = ["yusuke@slidict.io"]

  spec.summary       = "A gem for workflow-based notifications for Teams"
  spec.description   = "Nautilfer provides a robust and flexible way to send notifications to Microsoft Teams using workflow integrations."
  spec.homepage      = "https://github.com/slidict/nautilfer"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/slidict/nautilfer"
  spec.metadata["changelog_uri"] = "https://github.com/slidict/nautilfer/releases"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
