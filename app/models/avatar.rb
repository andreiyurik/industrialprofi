# Preset glyph avatars — a work glyph on a tinted disc, picked on /account.
# The glyphs are the existing emblem icons (assets), the choice is one string
# column on users: zero per-user storage, no uploads, no moderation (the same
# reasoning as the generated initials in AvatarsHelper, which stay the default).
class Avatar
  PRESETS = {
    "hard-hat" => { icon: "hard-hat-light", hue: "--lch-yellow" },
    "wrench" => { icon: "wrench-light", hue: "--lch-blue" },
    "lightning" => { icon: "lightning-light", hue: "--lch-orange" },
    "gear" => { icon: "gear-light", hue: "--lch-teal" },
    "cpu" => { icon: "cpu-light", hue: "--lch-pink" },
    "circuitry" => { icon: "circuitry-light", hue: "--lch-cyan" },
    "thermometer" => { icon: "thermometer-light", hue: "--lch-red" },
    "ruler" => { icon: "ruler-light", hue: "--lch-purple" },
    "toolbox" => { icon: "toolbox-light", hue: "--lch-green" },
    "gauge" => { icon: "gauge-light", hue: "--lch-blue" },
    "factory" => { icon: "factory-light", hue: "--lch-teal" },
    "pipe-wrench" => { icon: "pipe-wrench-light", hue: "--lch-orange" },
    "atom" => { icon: "atom-light", hue: "--lch-cyan" },
    "engine" => { icon: "engine-light", hue: "--lch-red" },
    "motorcycle" => { icon: "motorcycle-light", hue: "--lch-purple" },
    "shield-check" => { icon: "shield-check-light", hue: "--lch-green" },
    "camera" => { icon: "camera-light", hue: "--lch-pink" },
    "waveform" => { icon: "waveform-light", hue: "--lch-teal" },
    "certificate" => { icon: "certificate-light", hue: "--lch-yellow" },
    "chart-line-up" => { icon: "chart-line-up-light", hue: "--lch-green" }
  }.freeze

  class << self
    def tokens
      PRESETS.keys
    end

    def [](token)
      PRESETS[token]
    end
  end
end
