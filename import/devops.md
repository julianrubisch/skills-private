# DevOps / Infrastructure Reference

## Deployment

<!-- Native vs containerized, Kamal, Docker, PaaS tradeoffs -->

## Development Environment

<!-- Dev containers, reproducibility, team setup -->

## Feature Flags

<!-- Flipper patterns, rollout strategies, measuring impact -->

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

## Patterns
<!-- What good Rails infrastructure/devops looks like -->

## Anti-patterns
<!-- What to flag, and why -->

## Heuristics
<!-- Rules of thumb, judgment calls -->
