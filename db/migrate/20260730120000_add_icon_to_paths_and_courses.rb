class AddIconToPathsAndCourses < ActiveRecord::Migration[8.1]
  # The emblem used to live in two hashes in ApplicationHelper, which meant an
  # expert authoring a profession could not set it — only the founder, in Ruby,
  # with a deploy. Now it's an attribute of the row. Nil is meaningful: a course
  # inherits its profession's emblem, a profession falls back to the default.
  #
  # Literal copies of the hashes as they stood at this migration — a data
  # migration must not depend on code that will change under it.
  PATHS = {
    "elektrik" => "lightning-light",
    "svarshchik" => "hard-hat-light",
    "inzhener-asu-tp" => "cpu-light",
    "kipia-aes" => "atom-light",
    "operator-cnc" => "gear-light",
    "slesar-santehnik" => "pipe-wrench-light",
    "avtomehanik" => "engine-light",
    "fotograf-videograf" => "aperture-light"
  }.freeze

  COURSES = {
    "elektrik-bezopasnost-i-ohrana-truda" => "shield-check-light",
    "elektrik-osnovy-elektrotekhniki" => "waveform-light",
    "elektrik-pue-i-ustroystvo" => "book-bookmark-light",
    "elektrik-montazh" => "toolbox-light",
    "elektrik-izmerniya-i-ispytaniya" => "gauge-light",
    "elektrik-ekspluataciya-i-karera" => "chart-line-up-light",
    "elektrik-bytovoy" => "house-light",
    "elektrik-promyshlennyy" => "factory-light",
    "elektrik-cod" => "hard-drives-light",
    "asutp-osnovy-i-kipia" => "gauge-light",
    "asutp-elektricheskie-shemy" => "circuitry-light",
    "asutp-plk-i-regulirovanie" => "sliders-light",
    "asutp-promyshlennye-seti" => "tree-structure-light",
    "asutp-scada" => "monitor-light",
    "asutp-proektirovanie-pnr" => "list-checks-light",
    "aes-yadernaya-specifika" => "radioactive-light",
    "aes-kip-i-zashchity-vver" => "gauge-light",
    "cnc-professiya-i-karera" => "chart-line-up-light",
    "cnc-bezopasnost" => "shield-check-light",
    "cnc-metally-i-rezanie" => "cube-light",
    "cnc-cherteji-i-dopuski" => "ruler-light",
    "cnc-g-kod" => "code-light",
    "cnc-naladka" => "wrench-light",
    "cnc-kontrol-kachestva" => "seal-check-light",
    "slesar-bezopasnost" => "shield-check-light",
    "slesar-materialy" => "toolbox-light",
    "slesar-soedineniya" => "pipe-light",
    "slesar-vodosnabzhenie" => "drop-light",
    "slesar-kanalizatsiya" => "toilet-light",
    "slesar-otoplenie" => "thermometer-light",
    "slesar-dokumentatsiya" => "file-text-light",
    "svarshchik-bezopasnost" => "shield-check-light",
    "svarshchik-fizika-dugi" => "lightning-light",
    "svarshchik-metally" => "cube-light",
    "svarshchik-kontrol-kachestva" => "seal-check-light",
    "svarshchik-chertezhi" => "ruler-light",
    "svarshchik-tyazhelaya-promyshlennost" => "factory-light",
    "svarshchik-attestaciya-naks" => "certificate-light",
    "avtomehanik-tormoza-elektrika" => "lightning-light",
    "avtomehanik-diagnostika" => "monitor-light",
    "avtomehanik-to-normativy" => "list-checks-light",
    "avtomehanik-silovye-ustanovki" => "battery-charging-light",
    "avtomehanik-mototsikly" => "motorcycle-light",
    "fv-kadr-i-professiya" => "frame-corners-light",
    "fv-svet-i-zrenie" => "eye-light",
    "fv-optika" => "magnifying-glass-light",
    "fv-kamera-korobka" => "camera-light",
    "fv-ekspozitsiya" => "gauge-light",
    "fv-ohota-za-svetom" => "sun-light",
    "fv-kompozitsiya" => "grid-four-light",
    "fv-istoriya" => "film-slate-light",
    "fv-postprodakshn" => "sliders-light",
    "fv-rost-i-remeslo" => "chart-line-up-light"
  }.freeze

  def up
    add_column :paths, :icon, :string
    add_column :courses, :icon, :string

    # update_all, not each+save: the icon is not an authored edit, so it must not
    # touch updated_at (which drives caches) or fire IndexNow pings.
    PATHS.each { |slug, icon| Path.where(slug: slug).update_all(icon: icon) }
    COURSES.each { |slug, icon| Course.where(slug: slug).update_all(icon: icon) }
  end

  def down
    remove_column :paths, :icon
    remove_column :courses, :icon
  end
end
