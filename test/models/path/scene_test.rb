require "test_helper"

class Path::SceneTest < ActiveSupport::TestCase
  STEPS = [ { name: "Ввод", does: "питает", icon: "lightning-light", course: "el-basics" },
            { name: "Щит" }, { name: "Потребитель" }, { name: "Заземление" } ].freeze

  test "a scene needs all four steps named, or it is no scene" do
    assert_nil Path::Scene.normalize(steps: STEPS.first(3))
    assert_nil Path::Scene.normalize(steps: STEPS.first(3) + [ { name: " " } ])
    assert_nil Path::Scene.normalize(nil)
  end

  test "form params and pack arrays normalize to the same shape" do
    from_pack = Path::Scene.normalize(steps: STEPS, links: [ "230 В" ], top: { name: "Измерения" }, top_link: "протокол")
    from_form = Path::Scene.normalize("steps" => STEPS.each_with_index.to_h { |step, index| [ index.to_s, step ] },
                                      "links" => { "0" => "230 В", "1" => "", "2" => "", "3" => "" },
                                      "top" => { "name" => "Измерения", "does" => "" }, "top_link" => "протокол", "caption" => "")

    assert_equal from_pack, from_form
    assert_equal [ "230 В", "", "", "" ], from_pack["links"]
    assert_equal({ "name" => "Измерения" }, from_pack["top"])
  end

  test "an unknown icon and an overlong label are dropped or clipped, not rejected" do
    steps = STEPS.dup.tap { |list| list[1] = { name: "Щ" * 60, icon: "no-such-icon" } }
    scene = Path::Scene.new(Path::Scene.normalize(steps: steps))

    assert_equal Path::Scene::LIMITS["name"], scene.steps[1].name.length
    assert_equal Icon::DEFAULT_EMBLEM, scene.steps[1].emblem
    assert_equal "lightning-light", scene.steps[0].emblem
  end

  test "malformed scene data is empty, not an exception" do
    assert_nil Path::Scene.normalize("steps" => [ "Ввод", "Щит", "Потребитель", "Заземление" ], "top" => "Измерения")
    assert_nil Path::Scene.normalize("oops")
    assert_nil Path.normalize_landing("scene" => { "steps" => "x", "links" => { "a" => [ 1 ] } })["scene"]
  end

  test "a half-named scene is an error the form can show, with the draft kept" do
    path = paths(:electrician)
    path.scene = { steps: STEPS.first(2) }

    assert_not path.valid?
    assert path.errors.of_kind?(:scene, :incomplete)
    assert_equal %w[Ввод Щит], path.scene.steps.map(&:name).compact_blank
  end

  test "a scene alone makes the landing worth exporting" do
    paths(:electrician).update!(scene: { steps: STEPS })
    assert paths(:electrician).reload.landing_present?
  end

  test "a path stores its scene in the landing and drops it when the names are cleared" do
    path = paths(:electrician)
    path.update!(scene: { steps: STEPS, caption: "Цепь" })
    assert path.reload.scene.present?
    assert_equal "Цепь", path.scene.caption
    assert_equal %w[Ввод Щит Потребитель Заземление], path.scene.steps.map(&:name)

    path.update!(scene: { steps: STEPS.map { { name: "" } } })
    assert_not path.reload.scene.present?
    assert_not path.landing.key?("scene")
  end
end
