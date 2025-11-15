require "spec_helper"
require "open3"
require "rbconfig"

RSpec.describe "ActiveSupport extension" do
  let(:ruby) { RbConfig.ruby }
  let(:root) { File.expand_path("../..", __dir__) }

  it "adds #to_toon to Object even when ActiveSupport loads after toon" do
    script = <<~'RUBY'
      require "bundler/setup"
      $LOAD_PATH.unshift File.expand_path("lib", __dir__)

      require "toon"
      Object.send(:remove_method, :to_toon) if Object.method_defined?(:to_toon)

      require "active_support"
      require "active_support/core_ext/object"

      puts Object.new.respond_to?(:to_toon)
    RUBY

    stdout, stderr, status = Open3.capture3(
      { "BUNDLE_GEMFILE" => File.join(root, "Gemfile") },
      ruby,
      "-e",
      script,
      chdir: root
    )

    expect(status.success?).to eq(true), "stdout: #{stdout}\nstderr: #{stderr}"
    expect(stdout.strip).to eq("true")
  end
end
