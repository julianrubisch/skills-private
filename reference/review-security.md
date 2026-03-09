# Security Review Reference

Diagnostic layer — what to flag, how severe, and why. Prescriptive patterns
(how to write secure code) live in shared/security.md.

## Anti-patterns

### SQL Injection via String Interpolation

**Severity: Critical**

**Signal:** String interpolation inside `.where(...)`, `.order(...)`,
`.select(...)`, `find_by_sql(...)`, or any raw SQL call.

**Fix:** See `shared/security.md § SQL Injection`.

### XSS via `.html_safe` or `raw`

**Severity: High**

**Signal:** `.html_safe` on a string that wasn't produced by a Rails helper.
`raw` or `<%==` in templates. `innerHTML` in JavaScript.

**Fix:** See `shared/security.md § XSS Prevention`.

### Mass Assignment Without Strong Parameters

**Severity: Critical**

**Signal:** `params[:model]` passed directly to AR methods without `.permit`.
`params.permit!` anywhere.

**Fix:** See `shared/security.md § Strong Parameters`.

### Missing Authorization Scope (IDOR)

**Severity: High**

**Signal:** Bare `Model.find(params[:id])` in controllers without a
preceding scope or Pundit `authorize` call.

**Fix:** See `shared/security.md § Authorization Scoping`.

### Missing Content Security Policy

**Severity: Medium**

**Signal:** No CSP initializer, or a permissive one with `unsafe-eval`
or wildcard `*` sources.

**Fix:** See `shared/security.md § Content Security Policy`.

### Unprotected External URL Fetching (SSRF)

**Severity: High**

**Signal:** `Net::HTTP`, `HTTParty`, `Faraday`, or `open-uri` called with
a user-supplied URL without DNS pinning or IP range checks.

**Fix:** See `shared/security.md § SSRF Protection`.

### Command Injection

**Severity: Critical**

**Signal:** `system()`, backticks, `exec()`, `%x()`, or `IO.popen()` with
string interpolation of user input.

**Fix:** See `shared/security.md § Command Injection`.

### Path Traversal

**Severity: Critical**

**Signal:** `send_file`, `File.read`, or `render file:` with user-controlled
path. Look for `params[:filename]`, `params[:path]`, `params[:template]`.

**Fix:** See `shared/security.md § Path Traversal`.

### Missing Authentication

**Severity: Critical**

**Signal:** Controllers with destructive actions (`destroy`, `update`,
`create`) but no `before_action :authenticate_*`. Admin controllers
without authentication.

**Fix:** See `shared/security.md § Missing Authentication`.

### Sensitive Data Exposure

**Severity: High**

**Signal:** `params.inspect` or sensitive fields in log output. `render json:`
on full model objects without `.as_json(only: ...)`. Missing
`filter_parameters` for passwords/tokens.

**Fix:** See `shared/security.md § Sensitive Data Exposure`.

### Weak Cryptography

**Severity: High**

**Signal:** `Digest::MD5`, `Digest::SHA1` for password hashing. `Base64`
used as if it were encryption.

**Fix:** See `shared/security.md § Cryptography`.

### Insecure Session Configuration

**Severity: Medium**

**Signal:** Session store missing `secure: true`, `httponly: true`, or
`same_site:` options. No session expiry configured.

**Fix:** See `shared/security.md § Session Security`.

### CSRF Protection Disabled

**Severity: Medium**

**Signal:** `skip_before_action :verify_authenticity_token` in non-API
controllers. HTML forms without Rails form helpers (missing CSRF token).

**Fix:** See `shared/security.md § CSRF Protection`.

### Open Redirect

**Severity: Medium**

**Signal:** `redirect_to params[:return_to]` or `redirect_to request.referer`
without validation against an allowlist.

**Fix:** See `shared/security.md § Redirect Security`.

## Heuristics

- Every `find(params[:id])` without a scope is a potential IDOR — flag it
- `.html_safe` is a code smell in PRs — verify each one
- CSP violations in logs are worth investigating, not dismissing
- Check ActionText `allowed_tags` in any app using rich text
- `system()` with string interpolation is always Critical — no exceptions
- `params.permit!` is always a red flag — no exceptions
- Admin controllers without `before_action :authenticate_*` are Critical
- Any `redirect_to` with user-controlled input needs an allowlist check

## Security Audit Checklist

### Authentication
- [ ] All sensitive actions require authentication
- [ ] Password requirements enforced (length, complexity)
- [ ] Account lockout after failed attempts
- [ ] Secure password reset flow
- [ ] Session timeout configured

### Authorization
- [ ] Resources scoped to authorized users
- [ ] Admin actions protected
- [ ] Role-based access control where needed

### Input Validation
- [ ] All user input validated
- [ ] Strong parameters used
- [ ] File upload restrictions (type, size)
- [ ] No SQL interpolation

### Output Encoding
- [ ] No `raw` or `html_safe` with user input
- [ ] JSON responses don't expose sensitive data
- [ ] Logs filtered for sensitive data

### Configuration
- [ ] HTTPS enforced in production
- [ ] Secure session configuration
- [ ] CSRF protection enabled
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)

### Dependencies
- [ ] Gemfile.lock reviewed for vulnerabilities
- [ ] Using `bundler-audit` or similar
