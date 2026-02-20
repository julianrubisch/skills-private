# Performance Review Reference

## Patterns

### HTTP Caching with Conditional GET

Use `fresh_when` for ETags + Last-Modified in one call. Use `expires_in` for
time-based expiry on public content. Always scope ETags to the current user
to prevent cache leaks across accounts.

```ruby
# GOOD — ETag + Last-Modified, user-scoped
class ArticlesController < ApplicationController
  etag { current_user&.id }

  def show
    @article = Article.find(params[:id])
    fresh_when(@article)
  end
end

# GOOD — time-based expiry for public, shared content
def index
  @articles = Article.published
  expires_in(15.minutes, public: true)
end
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

### Full-text Search via Materialized View + GIN Index

For cross-table full-text search, a materialized view with GIN index outperforms
JOIN-based `pg_search` by ~300x on large datasets. Manage with the `scenic` gem.

```ruby
# db/views/searchable_posts_v01.sql
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

# Migration
add_index :searchable_posts, :search_vector, using: :gin
```

Sync the view via a background job triggered by model callbacks on write.

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
```

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

**Signal:** Bullet gem warnings, or `pg_stat_statements` showing the same
query repeated N times with different ID values.

### No HTTP Caching on Expensive Public Endpoints

**Problem:** Every request for the same public content hits the server and
database, even when the content hasn't changed.

**Signal:** High-traffic index or show actions with no `fresh_when`,
`expires_in`, or HTTP cache headers in the response.

**Fix:** Add `fresh_when(@record)` for record-based pages, `expires_in` for
time-stable public pages. Always add `etag { current_user&.id }` at the
controller level to prevent cross-user cache leaks.

### Sequential Scans on Large Tables

**Problem:** Foreign key columns or frequently filtered columns without indexes
cause full table scans as data grows.

**Signal:** `seq_scan - idx_scan` is positive and large in the diagnostic query
above. Common culprits: polymorphic `*_id` + `*_type` columns, `created_at`
on tables filtered by date range.

### Async Queries Without Connection Pool Awareness

**Problem:** `load_async` borrows an extra DB connection. With Puma +
Sidekiq on a small connection pool, this causes `ConnectionTimeoutError`
under load.

**Fix:** Size the pool to account for async usage:
`pool = puma_threads + sidekiq_concurrency + async_headroom`

## Heuristics

- Run the two index diagnostic queries on any app before claiming it's "fast"
- Every `has_many` or `belongs_to` touched in a view is a potential N+1
- ActiveStorage counts as two associations: always `includes(x_attachment: :blob)`
- `load_async` is free performance when two queries are independent — use it
- Materialized views are a read/write tradeoff: only worth it when search is frequent and writes are tolerable to be slightly stale
- Sequential scan is fine on tables under ~80KB — don't index everything
