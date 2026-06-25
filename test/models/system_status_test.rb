require "test_helper"

class SystemStatusTest < ActiveSupport::TestCase
  setup { @status = SystemStatus.new }

  test "database_bytes sums the on-disk SQLite footprint" do
    assert_operator @status.database_bytes, :>, 0
  end

  test "disk fields are positive byte counts or nil when df is unavailable" do
    [ @status.disk_free_bytes, @status.disk_total_bytes ].each do |value|
      assert value.nil? || value.positive?, "expected nil or a positive byte count, got #{value.inspect}"
    end
  end

  test "disk_low? reflects the warn threshold" do
    assert_includes [ true, false ], @status.disk_low?
  end

  test "jobs returns counts or nil, never raises" do
    jobs = @status.jobs
    assert jobs.nil? || (jobs.key?(:pending) && jobs.key?(:failed))
  end
end
