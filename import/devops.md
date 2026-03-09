# DevOps / Infrastructure Reference

## Deployment

<!-- Native vs containerized, Kamal, Docker, PaaS tradeoffs -->

## Development Environment

**Prefer dev containers** to isolate workloads and eliminate "works on my machine"
problems. Every project should ship a `.devcontainer/` directory.

### Setup

Start with `rails new --devcontainer` (Rails 7.2+) to scaffold the boilerplate.
Three files in `.devcontainer/`:

- **`devcontainer.json`** — features (Ruby, Node, PG client), extensions,
  env vars, `postCreateCommand` for `bin/setup`
- **`compose.yaml`** — services (app, database, Selenium for system tests),
  volume mounts, port mappings
- **`Dockerfile`** — minimal, extends the official Rails base image

### Key Patterns

- Mount SSH keys as **read-only bind mounts** for seamless Git operations
- `sleep infinity` in compose so containers stay up
- Puma binds to `0.0.0.0` (not `127.0.0.1`) for port accessibility
- Database as a separate compose service with persistent volumes

### Execution

- **VS Code / Cursor** — auto-detects `.devcontainer/`, offers to rebuild
- **`devcontainer-cli`** — standalone CLI for headless / CI use
- **GitHub Codespaces** — cloud-based, zero local setup

Reference: https://www.rorvswild.com/blog/2025/dev-containers-rails

## Feature Flags

<!-- Flipper patterns, rollout strategies, measuring impact -->

## Configuration Management

For most apps, `Rails.application.credentials` or `ENV.fetch("KEY")` is enough.
When settings grow to 10+ values across 3+ services, or for multi-tenant /
self-hosted apps, consider structured config objects with boot-time validation.

> See `shared/configuration.md` for the Anyway Config pattern, YAML source
> precedence, and when the abstraction earns its keep.

## Performance Benchmarking

### Load Testing

Use `oha`, `wrk`, or `k6` for HTTP load testing. Run regularly, not just
before launches. Candidate for CI integration.

```sh
# oha — realistic admin backend scenario (2 req/s, 20s, no keepalive)
oha -q 2 -z 20s --disable-keepalive --latency-correction http://localhost:3000/posts

# wrk — higher throughput scenario
wrk -t4 -c100 -d30s http://localhost:3000/posts
```

Key metrics to track: mean response time, p95, p99. Chart over time to catch regressions.

### Application Load Time

Use `bumbler` to identify slow requires at boot. Target: keep added boot time
from any single gem under ~50ms.

```sh
gem install bumbler
bumbler -t 50   # flag requires slower than 50ms
```

Compare against lightweight equivalents (e.g. Devise ~20ms, Ransack ~20ms)
as a calibration benchmark.

### Memory Store for Short-lived Application Data

A small `ActiveSupport::Cache::MemoryStore` is useful for caching data that's
expensive to compute, stable for the lifetime of a worker, and small enough
to fit in memory (e.g. file contents, computed hashes).

```ruby
# config/initializers/resource_registry.rb
module ResourceRegistry
  CACHE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

  def self.fetch(key, &block)
    CACHE.fetch(key, &block)
  end
end

# Usage
ResourceRegistry.fetch(file_path) { File.read(file_path) }
```

