# Security Review Reference

## Patterns

### XSS Prevention — Escape Before Marking Safe

```ruby
# GOOD — escape first, then mark safe
def formatted_content(text)
  simple_format(h(text)).html_safe
end
```

Never call `.html_safe` on user-supplied content directly.

### SSRF Protection — Pin DNS Resolution

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

Resolve DNS once, pin the IP to prevent TOCTOU attacks.

### Content Security Policy

```ruby
# config/initializers/content_security_policy.rb
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.base_uri    :none
    policy.form_action :self
    policy.frame_ancestors :self
  end
end
```

### ActionText Sanitization

```ruby
# config/initializers/action_text.rb
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_tags = %w[
    strong em a ul ol li p br h1 h2 h3 h4 blockquote
  ]
end
```

Restrict allowed tags explicitly — don't rely on ActionText defaults.

## Anti-patterns

### SQL Injection via String Interpolation

```ruby
# BAD
User.where("name = '#{params[:name]}'")

# GOOD
User.where(name: params[:name])
User.where("name = ?", params[:name])
```

### Mass Assignment Without Strong Parameters

```ruby
# BAD
User.update(params[:user])

# GOOD
User.update(user_params)

def user_params
  params.require(:user).permit(:name, :email)
end
```

### Calling `.html_safe` on User Input

Any string from user input, database, or external API must be escaped before
rendering. `.html_safe` is a declaration that you've already done this — not
a way to force rendering.

### Missing Authorization Checks

**Signal:** Controller actions that load records without checking ownership
or permissions. Any action reachable without authorization that operates on
a user-scoped resource.

**Fix:** Scope queries to the current user or account. Use Pundit policies
for non-trivial authorization logic.

```ruby
# BAD — any authenticated user can edit any card
def edit
  @card = Card.find(params[:id])
end

# GOOD — scoped to current account
def edit
  @card = Current.account.cards.find(params[:id])
end
```

## Heuristics

- Never interpolate user input into SQL strings
- Every `find` on a sensitive resource should be scoped to the current user/account
- `.html_safe` is a code smell — grep for it in PRs and verify each one
- CSP violations in logs are worth investigating, not dismissing
- External URL fetching requires SSRF protection

<!-- Add your own security rules below -->
