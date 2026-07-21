Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.credentials.dig(:github, :client_id),
    Rails.application.credentials.dig(:github, :client_secret),
    scope: "user:email"
end



OmniAuth.config.allowed_request_methods = [ :post ]

OmniAuth.config.allowed_request_methods = [ :post ]

OmniAuth.config.allowed_request_methods = [ :post ]

OmniAuth.config.silence_get_warning = true
