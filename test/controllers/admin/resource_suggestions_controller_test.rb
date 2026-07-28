require "test_helper"

class Admin::ResourceSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @lesson = lessons(:pteep) # profession: electrician
    @suggestion = @lesson.resource_suggestions.create!(
      author_name: "Иван", url: "https://ya.ru/gost", title: "ГОСТ 166-89", kind: "norm"
    )
    sign_in_as users(:admin)
  end

  # Auth

  test "index without auth redirects to sign-in" do
    sign_out
    get admin_resource_suggestions_path
    assert_redirected_to new_session_path
  end

  test "a plain member is closed out" do
    sign_out
    sign_in_as users(:member)
    get admin_resource_suggestions_path
    assert_response :redirect
  end

  # Index

  test "index lists a pending suggestion" do
    get admin_resource_suggestions_path
    assert_response :success
    assert_match "ГОСТ 166-89", response.body
  end

  # Approve / reject

  test "approve turns the suggestion into a resource and logs it" do
    assert_difference -> { @lesson.resources.count }, 1 do
      assert_difference -> { AdminAction.count }, 1 do
        patch approve_admin_resource_suggestion_path(@suggestion)
      end
    end

    assert_equal "approved", @suggestion.reload.status
    resource = @lesson.resources.find_by(title: "ГОСТ 166-89", origin: "human")
    assert resource
    assert_equal @suggestion.author_name, resource.contributor_name
  end

  test "reject closes it without creating a resource" do
    assert_no_difference -> { @lesson.resources.count } do
      patch reject_admin_resource_suggestion_path(@suggestion),
        params: { resource_suggestion: { reviewer_comment: "не по теме" } }
    end

    assert_equal "rejected", @suggestion.reload.status
    assert_equal "не по теме", @suggestion.reload.reviewer_comment
  end

  test "reject without a reason is refused" do
    patch reject_admin_resource_suggestion_path(@suggestion)

    assert_equal "pending", @suggestion.reload.status
    assert_redirected_to admin_resource_suggestions_path
  end

  test "an editor may moderate a granted profession" do
    sign_out
    sign_in_as users(:editor) # granted electrician in fixtures
    patch approve_admin_resource_suggestion_path(@suggestion)
    assert_equal "approved", @suggestion.reload.status
  end
end
