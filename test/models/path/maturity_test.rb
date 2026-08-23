require "test_helper"

class Path::MaturityTest < ActiveSupport::TestCase
  test "the needle climbs rung by rung — a higher fact without the lower ones does not lift it" do
    path = paths(:welder)
    assert_equal 1, path.maturity_stage, "material only"

    Editorship.create!(user: users(:editor), path: path)
    assert path.curated?
    assert_equal 1, path.maturity_stage, "a curator without accepted edits is still rung 1"

    lessons(:svarka_intro).lesson_suggestions.create!(author_name: "Читатель", body_markdown: "x", section: "body", status: "approved")
    assert_equal 3, path.reload.maturity_stage, "edits + curator = 3"

    path.update!(verified_at: Time.current, verified_by: users(:editor))
    assert_equal 4, path.maturity_stage
  end

  test "a mark on an uncurated map does not count, and cannot be set" do
    path = paths(:welder) # no curator, no edits
    path.update!(verified_at: Time.current, verified_by: users(:admin))
    assert path.verified?, "the raw fact is there"
    assert_equal 1, path.maturity_stage, "but it lifts nothing"
    assert_not path.verifiable?
    assert_raises(Path::Maturity::NotVerifiable) { path.verify!(users(:admin)) }
  end

  test "only a curator of this map may set the mark" do
    path = paths(:electrician) # curated + community-improved in fixtures
    assert path.verifiable?
    assert path.verifiable_by?(users(:editor))
    assert_not path.verifiable_by?(users(:admin)), "role is not a grant"
    assert_not path.verifiable_by?(nil)
    assert_raises(Path::Maturity::NotVerifiable) { path.verify!(users(:admin)) }
    path.verify!(users(:editor))
    assert_equal 4, path.maturity_stage
  end
end
