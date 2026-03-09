# Security: Shared Reference

Prescriptive guide — how to write secure Rails code. Loaded by both coding
skills and review agents. Review-specific concerns (what to flag, severity)
live in review-security.md.

## SQL Injection

Use parameterized queries. Never interpolate user input into SQL strings.

```ruby
# BAD
where("name = '#{params[:name]}'")
where("name LIKE '%#{term}%'")
find_by_sql("SELECT * FROM users WHERE id = #{id}")
order("#{params[:sort]} #{params[:direction]}")

# GOOD
where("name = ?", params[:name])
where("name LIKE ?", "%#{term}%")
where(name: params[:name])
order(Arel.sql(safe_order_string))
```

## XSS Prevention

Escape user content before rendering. Never call `.html_safe` on user-supplied
strings directly.

```ruby
# GOOD — escape first, then mark safe
def formatted_content(text)
  simple_format(h(text)).html_safe
end
```

```erb
<%# BAD — raw output %>
<%= raw user_input %>
<%= user_input.html_safe %>
<%== user_input %>

<%# GOOD — auto-escaped or sanitized %>
<%= user_input %>
<%= sanitize(user_input) %>
```

```javascript
// BAD
element.innerHTML = userInput;

// GOOD
element.textContent = userInput;
```

## Strong Parameters

Always whitelist at the controller boundary. Never pass `params` directly
to model methods.

```ruby
# BAD
params.permit!
User.new(params[:user])
update_attributes(params)

# GOOD
def user_params
  params.require(:user).permit(:name, :email)
end

User.new(user_params)
```

## Authorization Scoping

Scope all record lookups to the current user or account. Never look up
a record by ID alone without verifying ownership.

```ruby
# BAD — any authenticated user can access any record
@document = Document.find(params[:id])

# GOOD — scoped to current account
@document = Current.account.documents.find(params[:id])

# GOOD — Pundit authorization
@document = Document.find(params[:id])
authorize @document
```

Use Pundit policies for non-trivial authorization logic (see `patterns.md §
Policy Objects`).

## SSRF Protection

Resolve DNS once and pin the IP to prevent TOCTOU attacks on URL fetching.

```ruby
def fetch_safely(url)
  uri = URI.parse(url)
  ip  = Resolv.getaddress(uri.host)

  raise "Private IP" if private_ip?(ip)

  Net::HTTP.start(uri.host, uri.port, ipaddr: ip) { |http| http.get(uri.path) }
end

def private_ip?(ip)
  ip.start_with?("127.", "10.", "192.168.") ||
    ip.match?(/^172\.(1[6-9]|2[0-9]|3[0-1])\./)
end
```

## Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src    :self
    policy.script_src     :self
    policy.style_src      :self, :unsafe_inline
    policy.base_uri       :none
    policy.form_action    :self
    policy.frame_ancestors :self
  end
end
```

## ActionText Sanitization

Restrict allowed tags explicitly — don't rely on ActionText defaults.

```ruby
# config/initializers/action_text.rb
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_tags = %w[
    strong em a ul ol li p br h1 h2 h3 h4 blockquote
  ]
end
```

## Command Injection

```ruby
# BAD — shell interprets user input
system("convert #{params[:file]}")
`ls #{user_input}`
exec("command #{args}")
%x(command #{args})

# GOOD — array form bypasses shell interpretation
system("convert", params[:file])
```

## Path Traversal

```ruby
# BAD — user controls file path
send_file(params[:filename])
File.read(params[:path])
render file: params[:template]

# GOOD — restrict to basename, validate path
basename = File.basename(params[:filename])
safe_path = Rails.root.join("uploads", basename)
send_file(safe_path) if File.exist?(safe_path)
```

## Sensitive Data Exposure

```ruby
# BAD — logging or serializing sensitive data
Rails.logger.info("Password: #{params[:password]}")
Rails.logger.info(params.inspect)
render json: user  # may include password_digest, tokens

# GOOD — filter params, whitelist JSON
config.filter_parameters += [:password, :token, :secret]
render json: user.as_json(only: [:id, :name, :email])
```

## Cryptography

```ruby
# BAD — weak or non-encryption
Digest::MD5.hexdigest(password)
Digest::SHA1.hexdigest(password)
Base64.encode64(secret)  # encoding, not encryption

# GOOD
BCrypt::Password.create(password)        # via has_secure_password
ActiveSupport::MessageEncryptor           # for symmetric encryption
```

## Session Security

```ruby
# GOOD — secure session configuration
Rails.application.config.session_store :cookie_store,
  key: '_app_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax,
  expire_after: 30.minutes
```

## CSRF Protection

```ruby
# BAD — disabling CSRF entirely
class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
end

# GOOD — null session for stateless APIs, keep CSRF for browser requests
class ApiController < ApplicationController
  protect_from_forgery with: :null_session
end

# Always use Rails form helpers (include CSRF token automatically)
<%= form_with url: posts_path do |f| %>
```

## Redirect Security

```ruby
# BAD — open redirect
redirect_to params[:return_to]
redirect_to request.referer

# GOOD — validate against allowlist
ALLOWED_REDIRECTS = %w[/dashboard /profile /settings]
redirect_to params[:return_to] if ALLOWED_REDIRECTS.include?(params[:return_to])
```

## Missing Authentication

Every controller should require authentication unless explicitly public.

```ruby
# BAD — no authentication on destructive action
class AdminController < ApplicationController
  def destroy
    User.find(params[:id]).destroy
  end
end

# GOOD
class AdminController < ApplicationController
  before_action :authenticate_admin!

  def destroy
    User.find(params[:id]).destroy
  end
end
```
