class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Shared gate for every link a person types: resources, sources, map links.
  URL_FORMAT = /\Ahttps?:\/\/[^\s]+\z/i
end
