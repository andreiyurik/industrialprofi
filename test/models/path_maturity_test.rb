require "test_helper"

class PathMaturityTest < ActiveSupport::TestCase
  test "an untouched map sits on stage 1" do
    # The welder map has only a PENDING suggestion — pending must not count.
    assert_equal 1, paths(:welder).maturity_stage
  end

  test "approved reader edits lift a map to stage 2" do
    lesson_suggestions(:welder_suggestion).update!(status: "approved")
    assert_equal 2, paths(:welder).maturity_stage
  end

  test "an active editor's grant lifts a map to stage 3" do
    assert_equal 3, paths(:electrician).maturity_stage
  end

  test "a suspended curator's grant no longer counts" do
    users(:editor).suspend!
    assert_equal 2, paths(:electrician).maturity_stage
  end

  test "a demoted editor's dormant grant no longer counts" do
    users(:editor).update!(role: :member)
    assert_equal 2, paths(:electrician).maturity_stage
  end

  test "an expert mark past its shelf life stops counting" do
    path = paths(:electrician)
    path.verify!(users(:editor))

    travel Path::Maturity::VERIFICATION_TTL + 1.day do
      assert_equal 3, path.maturity_stage
      assert path.verification_expired?
      assert_includes Path.verification_expired, path

      path.verify!(users(:editor))
      assert_equal 4, path.maturity_stage
    end
  end

  test "verify! sets stage 4 and unverify! clears it" do
    path = paths(:electrician)
    path.verify!(users(:editor))
    assert_equal 4, path.maturity_stage
    assert_equal users(:editor), path.verified_by

    path.unverify!
    assert_equal 3, path.maturity_stage
    assert_nil path.verified_by
  end
end
