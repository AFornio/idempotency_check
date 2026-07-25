require "idempotency_check/rspec"
require_relative "setup"
require_relative "happy_job"
require_relative "bad_job"

RSpec.describe "idempotency_check matcher" do
  it "passes for a job that is idempotent" do
    expect { HappyJob.perform }.to be_idempotent
  end

  it "fails for a job that is not idempotent" do
    expect { BadJob.perform }.not_to be_idempotent
  end
end
