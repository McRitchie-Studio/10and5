require_relative "boot"

require "rails"
require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module TenAndFive
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    # No sign-in, and the one form (the demo scorecard) is a GET that saves
    # nothing: no session, so no cookie.
    config.session_store :disabled
  end
end
