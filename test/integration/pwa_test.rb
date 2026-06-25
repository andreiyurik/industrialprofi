require "test_helper"

class PwaTest < ActionDispatch::IntegrationTest
  test "manifest is served with brand identity and standalone display" do
    get "/manifest"
    assert_response :success
    assert_includes response.body, "industrialprofi"
    assert_includes response.body, "\"display\": \"standalone\""
    assert_includes response.body, "#000000"
  end

  test "service worker is served" do
    get "/service-worker"
    assert_response :success
    assert_includes response.body, "OFFLINE_URL"
  end

  test "layout links the manifest and enables native-feel transitions" do
    get root_path
    assert_select 'link[rel="manifest"]'
    assert_select 'meta[name="view-transition"][content="same-origin"]'
    assert_select 'meta[name="apple-mobile-web-app-capable"]'
  end
end
