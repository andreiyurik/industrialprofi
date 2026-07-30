require "test_helper"

# A mistyped icon name renders an empty span — invisible, and no error anywhere.
# This catches it. Service glyphs are referenced from code, so an unused one is an
# orphan; emblems are the PALETTE an expert picks from in the admin, so an unused
# emblem is expected and only its file/registry pairing is checked.
class IconTagTest < ActionView::TestCase
  include ApplicationHelper

  REGISTRY = Rails.root.join("app/assets/stylesheets/icons.css")
  SOURCES = Dir[Rails.root.join("app/**/*.erb")] + Dir[Rails.root.join("app/**/*.rb")]

  test "every icon_tag name is registered in icons.css" do
    missing = called_names - registered_names
    assert_empty missing, "не зарегистрированы в icons.css: #{missing.sort.join(', ')}"
  end

  test "every service glyph is used somewhere" do
    orphans = (registered_names - emblem_names) - mentioned_names
    assert_empty orphans, "лежат в icons.css, но никем не используются: #{orphans.sort.join(', ')}"
  end

  test "registry and files agree" do
    assert_empty registered_names - disk_names, "нет файла SVG: #{(registered_names - disk_names).sort.join(', ')}"
    assert_empty disk_names - registered_names, "файл есть, строки в icons.css нет: #{(disk_names - registered_names).sort.join(', ')}"
  end

  test "Icon.emblems matches the registry's light weight" do
    assert_equal emblem_names.sort, Icon.emblems
    assert_includes Icon.emblems, Icon::DEFAULT_EMBLEM
  end

  test "icon_tag renders a masked span" do
    assert_equal %(<span class="icon icon--check" aria-hidden="true"></span>), icon_tag("check")
  end

  test "icon_tag keeps a caller's own class" do
    assert_includes icon_tag("check", class: "reaction__heart"), %(class="icon icon--check reaction__heart")
  end

  private
    def registered_names
      REGISTRY.read.scan(/^\.icon--([\w-]+)\s*\{/).flatten
    end

    def disk_names
      Rails.root.glob("app/assets/images/icons/*.svg").map { it.basename(".svg").to_s }
    end

    def emblem_names
      registered_names.grep(/#{Icon::EMBLEM_SUFFIX}\z/)
    end

    # Strict, for the typo check: a literal first argument.
    def called_names
      SOURCES.flat_map { |file| File.read(file).scan(/icon_tag[( ]"([\w-]+)"/) }.flatten.uniq + table_names
    end

    # Permissive, for the orphan check: any string literal counts as a mention, which
    # covers ternaries without parsing Ruby (a stray match can only mask an orphan).
    def mentioned_names
      SOURCES.flat_map { |file| File.read(file).scan(/"([\w-]+)"/) }.flatten.uniq + table_names
    end

    # Names the callout and resource-badge tables feed to icon_tag indirectly.
    def table_names
      ApplicationHelper::CALLOUTS.values.map { it[:icon] } +
        ApplicationHelper::RESOURCE_KIND_BADGES.values.map { it[:icon] }
    end
end
