class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Every link a person types goes through the same gate — a resource, a
  # suggested source, a link on someone's map.
  URL_FORMAT = /\Ahttps?:\/\/[^\s]+\z/i
end
