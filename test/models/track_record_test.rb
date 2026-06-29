require "test_helper"

class TrackRecordTest < ActiveSupport::TestCase
  setup do
    @user = users(:member)
    @electrician = lessons(:pteep)     # path: electrician
    @welder = lessons(:svarka_intro)   # path: welder
  end

  test "a person with no suggestions is a newcomer with no rate yet" do
    record = TrackRecord.for(@user)

    assert_equal 0, record.submitted
    assert_equal 0, record.accepted
    assert_nil record.acceptance_rate
    assert_equal :newcomer, record.standing
    assert_empty record.professions_touched
  end

  test "counts submitted, accepted and rejected from the logs" do
    suggest @user, @electrician, status: "approved"
    suggest @user, @electrician, status: "approved"
    suggest @user, @electrician, status: "rejected"
    suggest @user, @electrician, status: "pending"

    record = TrackRecord.for(@user)

    assert_equal 4, record.submitted
    assert_equal 2, record.accepted
    assert_equal 1, record.rejected
    assert_equal 3, record.decided
    assert_in_delta 2.0 / 3.0, record.acceptance_rate, 0.001
  end

  test "standing stays newcomer below the trusted threshold" do
    2.times { suggest @user, @electrician, status: "approved" }
    assert_equal :newcomer, TrackRecord.for(@user).standing
  end

  test "standing becomes trusted once enough edits are accepted" do
    TrackRecord::TRUSTED_AT.times { suggest @user, @electrician, status: "approved" }
    assert_equal :trusted, TrackRecord.for(@user).standing
  end

  test "standing becomes expert with volume and a healthy acceptance rate" do
    TrackRecord::EXPERT_AT.times { suggest @user, @electrician, status: "approved" }
    assert_equal :expert, TrackRecord.for(@user).standing
  end

  test "volume alone does not earn expert when the acceptance rate is poor" do
    TrackRecord::EXPERT_AT.times { suggest @user, @electrician, status: "approved" }
    TrackRecord::EXPERT_AT.times { suggest @user, @electrician, status: "rejected" }

    record = TrackRecord.for(@user)
    assert record.acceptance_rate < TrackRecord::HEALTHY_RATE
    assert_equal :trusted, record.standing
  end

  test "a path slice isolates trust to one profession" do
    suggest @user, @electrician, status: "approved"
    suggest @user, @electrician, status: "approved"
    suggest @user, @welder, status: "approved"

    assert_equal 2, TrackRecord.for(@user, path: paths(:electrician)).accepted
    assert_equal 1, TrackRecord.for(@user, path: paths(:welder)).accepted
  end

  test "professions_touched lists only paths with an accepted edit, in catalog order" do
    suggest @user, @welder, status: "approved"          # welder is position 2
    suggest @user, @electrician, status: "approved"     # electrician is position 1
    suggest @user, @electrician, status: "rejected"     # rejected-only path must not appear

    touched = TrackRecord.for(@user).professions_touched
    assert_equal [ paths(:electrician), paths(:welder) ], touched.to_a
  end

  test "accepted_by_profession counts accepted edits per path in catalog order" do
    suggest @user, @welder, status: "approved"
    suggest @user, @electrician, status: "approved"
    suggest @user, @electrician, status: "approved"
    suggest @user, @electrician, status: "rejected"     # not counted

    assert_equal [ [ paths(:electrician), 2 ], [ paths(:welder), 1 ] ],
      TrackRecord.for(@user).accepted_by_profession
  end

  private

  def suggest(user, lesson, status:, section: "body")
    LessonSuggestion.create!(
      user: user, lesson: lesson, author_name: user.name,
      body_markdown: "Предложение", section: section, status: status
    )
  end
end
