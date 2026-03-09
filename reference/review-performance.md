# Performance Review Reference

## Audit Framework

A performance review has four sections — work through them in order:

1. **Frontend** — everything after HTML leaves the server (Core Web Vitals / PageSpeed, images, lazy loading, preloading) — defer to hwc-* skills for browser/JS specifics
2. **Database** — I/O between app and DB (N+1, indexes, query count, eager loading)
3. **Ruby/Memory** — timing and memory benchmarks of application code
4. **Environment** — app server config, cache stores, load testing

### Tooling

Add to bundle for profiling (remove after audit):

| Concern | Gem |
|---------|-----|
| N+1 detection | `prosopite` |
| Request profiling | `rack-mini-profiler` |
| Memory profiling | `memory_profiler` |
| CPU profiling | `stackprof`, `ruby-prof` |
| Require-time memory | `derailed_benchmarks` |
| Process memory | `get_process_mem` |

Global installs:
- `fasterer` — Ruby benchmark linting
- `bumbler` — application load time by require (`bumbler -t 50`)

Load testing: `oha`, `wrk`, or `k6` (cloud). Example: `oha -q 2 -z 20s --disable-keepalive --latency-correction`

---

## Patterns

### HTTP Caching with Conditional GET

Three separate `etag` concerns — keep them distinct:

```ruby
# 1. Global version buster — bump "v1" to invalidate all ETags app-wide
class ApplicationController < ActionController::Base
  etag { "v1" }
end

# 2. User-scope guard — prevents serving cached content across accounts
class ApplicationController < ActionController::Base
  etag { current_user&.id }
end

# 3. Per-action ETags — record-based (show) and collection-based (index)
class CardsController < ApplicationController
  def show
    @card = Card.find(params[:id])
    fresh_when etag: [@card, Current.user.timezone]
    # Timezone must be in ETag: times render server-side in user's timezone
  end

  def index
    @cards = @board.cards.preloaded
    fresh_when etag: [@cards, @board.updated_at]
  end
end
```

Use `expires_in` for time-based expiry on public, shared content (no user context):

```ruby
def index
  @articles = Article.published
  expires_in 15.minutes, public: true
end
```

### Cache-Control Headers and Cache Leak Prevention

`fresh_when` and `expires_in` set `Cache-Control` headers. Understand the
directives they control:

| Directive | Meaning |
|-----------|---------|
| `private` | Only the browser may cache (default in Rails) |
| `public` | Any shared cache (CDN, proxy) may cache |
| `no-cache` | Cache may store, but must revalidate with origin before serving |
| `no-store` | Cache must not store any part of the response |
| `max-age=N` | Response is fresh for N seconds |
| `s-maxage=N` | Like max-age but for shared caches only (CDN) |
| `stale-while-revalidate=N` | Serve stale content for N seconds while revalidating in background |

```ruby
# CDN-friendly with stale-while-revalidate fallback
def index
  @articles = Article.published
  expires_in 5.minutes, public: true, stale_while_revalidate: 1.minute
end

# Prevent caching entirely for sensitive pages
def billing
  response.headers["Cache-Control"] = "no-store"
end
```

**Cache leak prevention checklist:**
- Always scope ETags to `current_user&.id` — a missing user scope means User A
  can receive User B's cached response from a shared cache.
- Never use `public: true` on pages that contain user-specific content.
- Add `Vary: Accept` header when the same URL serves HTML and JSON (Turbo).
- If using a CDN, ensure authenticated endpoints send `Cache-Control: private`
  — Rails does this by default, but verify it's not overridden.

### Fragment and Russian Doll Caching

Cache partials at the fragment level. Nest cache blocks for automatic
invalidation propagated via `touch: true`.

```erb
<%# Russian doll: board cache invalidates when any card changes %>
<% cache @board do %>
  <% @board.cards.each do |card| %>
    <% cache card do %>
      <%= render card %>
    <% end %>
  <% end %>
<% end %>
```

```ruby
# touch: true propagates updated_at up the association chain
class Comment < ApplicationRecord
  belongs_to :card,  touch: true
end

class Card < ApplicationRecord
  belongs_to :board, touch: true
end
# Comment update → card.updated_at changes → board.updated_at changes → cache busted
```

### `.size` vs `.count` on Loaded Relations

If a relation has already been loaded, count it in memory. `.count` fires a
new SQL query regardless.

```ruby
@posts = Post.all
@posts.count  # BAD — new COUNT query
@posts.size   # GOOD — counts in memory if already loaded
```

Only applies when the relation is actually used downstream. If you never
iterate `@posts`, use `Post.count` directly.

### Turbo Frame Lazy Loading for Expensive Sub-views

Associations shown on a show page (e.g. a user's posts, a project's tasks)
don't need to be in the initial response. Wrap them in a lazy Turbo Frame.

```erb
<%# Renders a spinner, then fetches content separately %>
<%= turbo_frame_tag "user_posts", src: user_posts_path(@user), loading: :lazy %>
```

This defers the DB query and rendering to a separate request, improving
initial response time and perceived performance.

### Preloading Hero Images

Add a `<link rel="preload">` for the most prominent image on a show/edit page
to improve Largest Contentful Paint.

```erb
<%# In layout or view %>
<%= preload_link_tag url_for(@resource.cover_image), as: :image %>
```

### Memoization for Expensive Method Calls

Memoize methods that are called multiple times per request but return the same
value. Common in helpers, decorators, and components.

```ruby
# GOOD — computed once per instance lifetime
def permitted_actions
  @permitted_actions ||= policy.actions_for(current_user, resource)
end

# For methods that can return nil or false, ||= silently re-evaluates.
# Use defined? or an explicit sentinel:
def cached_result
  return @cached_result if defined?(@cached_result)
  @cached_result = expensive_computation
end
```

**Where to look for missing memoization:**
- ViewComponent methods called from the template multiple times
- Policy/authorization checks repeated across partials
- Configuration lookups that hit the database (e.g. `Tenant.current.settings`)
- Methods called inside loops that return the same value every iteration

**Anti-pattern — memoizing at the class level by accident:**

```ruby
# BAD — persists across requests in a threaded server (Puma)
def self.settings
  @@settings ||= Setting.current
end

# GOOD — use RequestStore or Current attributes for per-request memoization
def settings
  RequestStore[:settings] ||= Setting.current
end
```

### ViewComponent Collection Rendering

Use `render ComponentName.with_collection(items)` instead of iterating with
`each`. ViewComponent's collection rendering is significantly faster.

```ruby
# GOOD
<%= render Avo::Index::GridItemComponent.with_collection(@resources) %>

# BAD — renders each component separately
<% @resources.each do |resource| %>
  <%= render Avo::Index::GridItemComponent.new(resource: resource) %>
<% end %>
```

### Eager Loading Associations

Declare all associations touched in a view up front. Includes ActiveStorage —
its `Attachment` and `Blob` models are associations like any other.

```ruby
# GOOD
def index
  @posts = Post.includes(:author, :tags, image_attachment: :blob)
end
```

### Async Queries for Independent DB Calls (Rails 7.0.1+)

When a controller action makes two independent queries (e.g. results + count
for pagination), run them concurrently with `load_async`.

```ruby
# GOOD — count and results run in parallel
def index
  @posts = Post.published.order(:created_at).load_async
  @count = Post.published.async_count
end
```

### Pagy Async Count for Pagination

Pagy normally runs a synchronous `COUNT(*)` before fetching results. Even with
`load_async` on the results query, the count blocks the controller. Fix by
running the count asynchronously too, then passing the resolved value to Pagy.

```ruby
def index
  scope = Post.published.order(:created_at)

  # Fire both queries concurrently — neither blocks until .value / iteration
  count_promise = scope.async_count
  @posts = scope.load_async

  # Pagy accepts a pre-computed count — .value blocks only when needed
  @pagy = Pagy.new(count: count_promise.value, page: params[:page])
  @posts = @posts.offset(@pagy.offset).limit(@pagy.limit)
end
```

**Why this matters:** On tables with millions of rows, `COUNT(*)` can take
hundreds of milliseconds. Without async count, total wall time is
`count_time + results_time`. With both async, it's `max(count_time, results_time)`.

**Pool sizing caveat:** Each async query borrows an additional connection. Size
your pool accordingly (see "Async Queries Without Connection Pool Awareness"
anti-pattern below).

### Full-text Search via Materialized View + GIN Index

For cross-table full-text search, a materialized view with GIN index outperforms
JOIN-based `pg_search` by ~300x on large datasets. Manage with the `scenic` gem.

```sql
-- db/views/searchable_posts_v01.sql
SELECT posts.id,
       to_tsvector('english',
         coalesce(posts.title, '') || ' ' ||
         coalesce(authors.name, '') || ' ' ||
         coalesce(string_agg(tags.name, ' '), '')
       ) AS search_vector
FROM posts
JOIN authors ON authors.id = posts.author_id
LEFT JOIN taggings ON taggings.post_id = posts.id
LEFT JOIN tags ON tags.id = taggings.tag_id
GROUP BY posts.id, posts.title, authors.name
```

```ruby
# Migration
add_index :searchable_posts, :search_vector, using: :gin
```

Sync the view via a background job triggered by model callbacks on write.

#### Scenic Gem Workflow

The `scenic` gem manages materialized views through standard Rails migrations:

```bash
# Generate the initial view (creates SQL file + migration)
bin/rails generate scenic:view searchable_posts

# Creates:
#   db/views/searchable_posts_v01.sql        — write your SELECT here
#   db/migrate/..._create_searchable_posts.rb

# To update the view later, generate a new version:
bin/rails generate scenic:view searchable_posts
#   db/views/searchable_posts_v02.sql        — new SQL definition
#   db/migrate/..._update_searchable_posts_to_version_2.rb
```

```ruby
# The model backs the view — set it as read-only
class SearchablePost < ApplicationRecord
  self.primary_key = :id

  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end
end

# Refresh concurrently requires a unique index on the materialized view
add_index :searchable_posts, :id, unique: true
```

**Refresh strategies:**
- `concurrently: true` — does not lock reads during refresh (requires unique index)
- Trigger refresh from an `after_commit` callback via a background job
- For high-write apps, debounce refreshes (e.g. at most once per minute)

### Database Index Diagnostics

Two SQL queries worth running during any performance review:

```sql
-- 1. Find tables likely missing indexes (skip tables < 80KB — seq scan wins there)
SELECT relname,
       seq_scan - idx_scan AS too_much_seq,
       CASE WHEN seq_scan - coalesce(idx_scan, 0) > 0
            THEN 'Missing Index' ELSE 'OK' END AS status,
       pg_relation_size(relname::regclass) AS rel_size
FROM pg_stat_all_tables
WHERE schemaname = 'public'
  AND pg_relation_size(relname::regclass) > 80000
ORDER BY too_much_seq DESC;

-- 2. Measure index efficiency (cache hit ratio — sort ASC to find worst offenders)
SELECT relname AS table_name,
       (idx_blks_hit * 1.0 / (idx_blks_hit + idx_blks_read)) AS index_efficiency
FROM pg_statio_user_tables
WHERE idx_blks_read + idx_blks_hit > 0
ORDER BY index_efficiency ASC
LIMIT 10;

-- 3. Find unused indexes (candidates for removal — saves write overhead)
SELECT schemaname, relname AS table_name,
       indexrelname AS index_name,
       idx_scan AS times_used,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexrelname NOT LIKE '%_pkey'
  AND indexrelname NOT LIKE '%unique%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- 4. Find duplicate indexes (same columns indexed multiple times)
SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS size,
       (array_agg(idx))[1] AS idx1, (array_agg(idx))[2] AS idx2
FROM (
  SELECT indexrelid::regclass AS idx,
         (indrelid::text || E'\n' || indclass::text || E'\n' ||
          indkey::text || E'\n' || coalesce(indexprs::text, '') || E'\n' ||
          coalesce(indpred::text, '')) AS key
  FROM pg_index
) sub
GROUP BY key HAVING count(*) > 1
ORDER BY sum(pg_relation_size(idx)) DESC;
```

**When to act:**
- **Unused indexes** (query 3): Remove after stats have accumulated for weeks.
  Exception: unique indexes enforce constraints regardless of scan count.
- **Duplicate indexes** (query 4): A composite index on `(a, b)` covers queries
  on `a` alone — a separate index on just `a` is wasted space and write overhead.

## Anti-patterns

### N+1 Queries

**Problem:** Associations loaded inside a loop — one query per record.
Especially common with ActiveStorage, which has two levels of association
(`Attachment` → `Blob`).

```ruby
# BAD — N+1 on attachment, then N+1 on blob
def index
  @users = User.all
end
# In view: user.avatar.url → hits DB for every user, twice

# GOOD
def index
  @users = User.includes(avatar_attachment: :blob)
end
```

ActiveStorage N+1 has two levels — the `Attachment` record and the `Blob` record.
ActiveStorage provides scoped helpers for bulk-loading:

```ruby
# For specific attachments
User.with_attached_avatar          # eager loads avatar + blob
Post.with_attached_images          # eager loads images + blobs

# In an index action
@users = User.all.with_attached_avatar.with_attached_cover
```

Detection tools: `prosopite` middleware (preferred), or `strict_loading!` on
the relation to surface unloaded associations with exceptions during development.

**Signal:** Bullet gem warnings, or `pg_stat_statements` showing the same
query repeated N times with different ID values.

### No HTTP Caching on Expensive Public Endpoints

**Problem:** Every request for the same public content hits the server and
database, even when the content hasn't changed.

**Signal:** High-traffic index or show actions with no `fresh_when`,
`expires_in`, or cache headers in the response.

**Fix:** `fresh_when(@record)` for record-based pages, `expires_in` for
time-stable public pages. Always scope ETags to `current_user&.id` to prevent
cross-user cache leaks.

### Sequential Scans on Large Tables

**Problem:** Foreign key columns or frequently filtered columns without indexes
cause full table scans as data grows.

**Signal:** `seq_scan - idx_scan` is positive and large in the diagnostic query
above. Common culprits: polymorphic `*_id` + `*_type` columns, `created_at`
on tables filtered by date range.

### Async Queries Without Connection Pool Awareness

**Problem:** `load_async` borrows an extra DB connection. With Puma + Solid Queue
on a small pool, this causes `ConnectionTimeoutError` under load.

**Fix:** Size the pool to account for async usage:
`pool = puma_threads + job_concurrency + async_headroom`



### Doing in Ruby what should be done in SQL

**Detection**:
- `Model.all.select`, `all.map`, `all.reject` (loading entire tables)
- Ruby sorting/filtering after loading records
- `association.length` instead of `association.count`
- Ruby `inject`/`reduce` for sums that could be SQL aggregations

**Severity**: High

**Solutions**:
```ruby
# Bad: Loads ALL orders into Ruby memory
Order.all.select { |o| o.total > 100 }

# Good: Database does the work
Order.where("total > ?", 100)

# Bad: Loads all records to count
user.posts.length

# Good: SQL count
user.posts.count
# Or: user.posts.size (uses counter cache if available)

# Bad: Ruby sum
Order.all.map(&:total).sum

# Good: SQL sum
Order.sum(:total)
```

**Audit Check**: Search for `.all.select`, `.all.map`, `.all.reject`, `.all.each` in models/controllers. Flag `.length` on associations.


## Heuristics

- Run the two index diagnostic queries on any app before claiming it's "fast"
- Every `has_many` or `belongs_to` touched in a view is a potential N+1
- ActiveStorage counts as two associations: always `includes(x_attachment: :blob)`
- `load_async` is free performance when two queries are independent — use it
- Materialized views are a read/write tradeoff: only worth it when search is frequent and write latency is acceptable
- Sequential scan is fine on tables under ~80KB — don't index everything
- Timezone in the ETag is not optional when times render server-side
- Pagy's COUNT query is a hidden sequential bottleneck — use `async_count` + `Pagy.new(count:)` to parallelize it
- Memoize any method called more than once per request that hits the DB or does non-trivial computation
- Unused indexes waste disk and slow writes — audit with `pg_stat_user_indexes` periodically
- `stale_while_revalidate` gives users instant responses while the cache refreshes in the background


### Additional Heuristic to find missing indexes

Missing Database Indexes

**Pattern**: Tables missing indexes on commonly queried columns.

**Detection**:
- Foreign key columns (`*_id`) without indexes
- Polymorphic type/id pairs without composite indexes
- Columns used in `validates :uniqueness` without unique indexes
- STI `type` columns without indexes
- Columns used in `to_param` (slugs) without indexes
- State/status columns used in `where` without indexes

**Severity**: High (performance)

**Solutions**:
```ruby
# Foreign keys need indexes
add_index :posts, :user_id

# Polymorphic associations need composite indexes
add_index :comments, [:commentable_type, :commentable_id]

# Uniqueness validations need unique indexes
add_index :users, :email, unique: true

# STI needs type index
add_index :vehicles, :type

# Slugs need indexes
add_index :posts, :slug, unique: true
```

**Audit Check**:
```bash
# Find foreign key columns without indexes
# Compare *_id columns in schema.rb against add_index statements
```

Flag: Any `*_id` column without index. Any `validates :uniqueness` without database-level unique index.
