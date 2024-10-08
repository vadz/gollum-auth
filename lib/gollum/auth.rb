require 'digest'
require 'rack'
require 'gollum/auth/version'
require 'gollum/auth/request'
require 'gollum/auth/user'

module Gollum
  module Auth
    def self.new(*args)
      App.new(*args)
    end

    class App
      def initialize(app, users, opts = { })
        @app = app
        users.each { |args| User.new(args).save! }
        @opts = { allow_unauthenticated_readonly: false }.merge(opts)
      end

      def call(env)
        request = Request.new(env)
        if request.requires_authentication?(@opts[:allow_unauthenticated_readonly])
          auth = Rack::Auth::Basic::Request.new(env)
          if auth.provided? && auth.basic? && user = User.find_by_credentials(auth.credentials)
            request.store_author_in_session(user)
          else
            return not_authorized
          end
        end
        @app.call(env)
      end

      private

      def not_authorized
        [
          401,
          {
            'content-type'     => 'text/plain',
            'www-authenticate' => 'Basic realm="Gollum Wiki"'
          },
          [ 'Not authorized' ]
        ]
      end
    end
  end
end
