module Admin
  class BaseController < ApplicationController
    http_basic_authenticate_with(
      name: Rails.application.credentials.dig(:admin_name) || ENV.fetch("ADMIN_NAME"),
      password: Rails.application.credentials.dig(:admin_password) || ENV.fetch("ADMIN_PASSWORD")
    )
  end
end
