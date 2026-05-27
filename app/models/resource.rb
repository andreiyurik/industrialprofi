class Resource < ApplicationRecord
  belongs_to :lesson

  validates :title, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\//i }
  validates :kind, inclusion: { in: %w[document video article tool] }

  scope :ordered, -> { order(:position) }
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :for_country, ->(code) { where(country_code: [ nil, code ]) }
end
