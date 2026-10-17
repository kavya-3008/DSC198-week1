# SQL study and teaching guide (Session 4 event log)

Built from: `README.md`, `lab_queries.sql`, `exercises.sql`, `solutions/INSTRUCTOR_NOTES.md`, `solutions/exercises_solved.sql`, and what we found running the log. It does not repeat the exercise answers. Those stay in `solutions/exercises_solved.sql`.

## 1. The one idea to teach first

**Every SQL query is: pick rows, group them, pick columns, sort.** Teach the clauses in the order the database *runs* them, not the order you write them.

| Written order | Runs in this order | What it does |
|---|---|---|
| `SELECT` | 5 | choose and compute columns |
| `FROM` / `JOIN` | 1 | build the combined set of rows |
| `WHERE` | 2 | filter individual rows (before grouping) |
| `GROUP BY` | 3 | bucket rows |
| `HAVING` | 4 | filter buckets (after grouping) |
| `ORDER BY` / `LIMIT` | 6 | sort, then cut |

This one table explains the most common student bug: an aggregate such as `COUNT(*) >= 3` in `WHERE` fails because the buckets don't exist yet. It belongs in `HAVING`.

## 2. The data: three tables

| Table | One row is | Key columns |
|---|---|---|
| `users` | a person who signed up | `user_id`, `signup_ts`, `campus`, `program` |
| `events` | one thing a person did | `event_id`, `user_id`, `event_type`, `occurred_ts`, `platform` |
| `calendar` | one day in October | `day` |

`events.user_id` points to `users.user_id`. That link is what a `JOIN` follows.

Seeded counts to check against: 400 users, 12,316 events, 31 calendar days.

## 3. Teaching sequence (about 60 to 90 minutes)

Rule for every step: **students predict the output on paper before they run it.** The prediction is the learning, not the result.

### Step 1: look before you query (5 min)
`SHOW TABLES;`, `SELECT * FROM users LIMIT 5;`, `.schema events`.
Say out loud what one row means: "a person did X at time Y on platform Z."

### Step 2: filter, group, count (15 min)
```sql
SELECT occurred_ts::DATE AS day, COUNT(*) AS events
FROM events GROUP BY day ORDER BY day;
```
Teach: `::DATE` casts, `AS` renames, `GROUP BY` makes buckets, `COUNT(*)` counts rows per bucket.
Then `COUNT(DISTINCT user_id)`. Ask: why are the two numbers different? (One person does several things per day. About 3 events per user per day in this log.)

### Step 3: the day that disappears (10 min)
The output has 30 rows, not 31. **Oct 12 has no events, so `GROUP BY` never creates its bucket.**
Fix: start from `calendar` and `LEFT JOIN` events. A `LEFT JOIN` keeps every row from the left table even when nothing matches, so Oct 12 returns with 0.
Rule to teach: *to count zero, start from the table that lists everything.*

### Step 4: WHERE versus HAVING (10 min)
Users with three or more applies. Have students try the condition in `WHERE` and read the error, then fix it with `HAVING`.

### Step 5: the main lesson, `NOT IN` versus the anti-join (15 min)
"Users who never applied."
- `NOT IN (subquery)` returns **0 rows**. The subquery contains NULLs (240 events have no `user_id`), and `x NOT IN (..., NULL)` is never true.
- The anti-join returns **103 rows**:
  ```sql
  FROM users u
  LEFT JOIN events e ON e.user_id = u.user_id AND lower(e.event_type) = 'apply'
  WHERE e.user_id IS NULL
  ```
Why it works: the `LEFT JOIN` keeps users with no apply event, and for those the right side is all NULL. The condition goes in `ON`, not `WHERE`, so non-apply events don't remove users.
Rule: *NULL is not a value, so comparisons with it are neither true nor false.*

### Step 6: cleaning, then CTEs (15 min)
Wrap the cleanup in a `WITH` block so each step has a name (`clean`, `searchers`, `appliers`). `DISTINCT` removes duplicate rows; `lower()` fixes casing.
Close with `COUNT(*)` against `COUNT(DISTINCT event_id)`: 12,316 against 12,136.

### Step 7: windows and timezones (stretch, from the exercises)
- `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY occurred_ts)` numbers rows within each user. `PARTITION BY` is like `GROUP BY` that keeps all the rows.
- `COUNT(*) FILTER (WHERE ...)` counts one condition per column, so you can compare two counts in one query.
- `signup_ts` is Pacific and `occurred_ts` is UTC, so convert one before comparing them. Pacific is UTC-7 in October.

## 4. The four deliberate flaws

| Flaw | How to spot it | Effect on a query |
|---|---|---|
| Duplicate rows (same `event_id`) | `COUNT(*)` greater than `COUNT(DISTINCT event_id)`, 180 extra rows | inflated counts |
| Mixed case in `event_type` | `GROUP BY event_type` gives 7 rows for 4 values (`Apply`, `APPLY`, `Save`) | missed rows unless you use `lower()` |
| UTC versus Pacific timestamps | compare `signup_ts` and `occurred_ts` | off by up to 8 hours |
| Events with no `user_id` | `WHERE user_id IS NULL`, 240 rows | `NOT IN` returns nothing, `JOIN` drops them |

Other things to know:
- **Oct 12 has no events.** This is a gap, not a flaw. It's why `calendar` exists.
- **3,828 events happen before the user's `signup_ts`.** This isn't one of the four listed flaws. I don't know the cause, and the timezone offset alone can't explain it, since users who signed up on Oct 19 or 20 appear active on Oct 1. Treat it as a question to raise with students, not an answer to teach.
- Every day has exactly 135 distinct users. That looks like a property of the generator, not real behavior.

Teach the habit: **before trusting any number, run a sanity check** (row count against distinct ids, `IS NULL` counts, `GROUP BY` on every categorical column, min and max dates).

## 5. How to get students writing their own queries

Use this checklist. Students answer each line in a comment before writing SQL:

1. **What is one row of my answer?** (a user? a day? a campus?)
2. **Which table has the thing I count?**
3. **Do I need to join? On which column?**
4. **Do I need rows that match nothing?** If yes, `LEFT JOIN` from the complete table.
5. **Filter rows (`WHERE`) or filter groups (`HAVING`)?**
6. **What could be NULL, duplicated, or inconsistently written?**
7. **Predict the row count before running.**

Method:
- Build every query in layers: `SELECT *` first, then add the filter, then the grouping, then the sort. Never write the whole thing at once.
- When wrong, check the row count first, then the first five rows, then the join condition.
- Have students explain a result to a partner in one sentence before moving on.

## 6. Practice set

Write the one-row-means comment first. Answers are in `solutions/`, so write yours before opening them.

- `exercises.sql` E1 to E4: applications per campus, first event per user (with and without a window), days where applies outnumbered searches, and users who were inactive in the week after signup.
- Extra ideas on this log: the platform split of events; the campus with the highest share of users who applied; the most active day of the week; users with events on more than one platform.
- Break-it drills: put an aggregate in `WHERE`; use `NOT IN` on a column with NULLs; use `GROUP BY event_type` without `lower()`; join to `calendar` with an inner join and notice the missing day.

## 7. Quick reference

| Task | Pattern |
|---|---|
| Count per group | `SELECT x, COUNT(*) FROM t GROUP BY x` |
| Count people, not rows | `COUNT(DISTINCT user_id)` |
| Filter groups | `GROUP BY ... HAVING COUNT(*) >= 3` |
| Keep unmatched rows | `LEFT JOIN` |
| Find "who never did X" | anti-join: `LEFT JOIN ... ON ... WHERE right.key IS NULL` |
| Count a condition | `COUNT(*) FILTER (WHERE cond)` |
| Rank within a group | `ROW_NUMBER() OVER (PARTITION BY g ORDER BY ts)` |
| Name an intermediate step | `WITH name AS (SELECT ...)` |
| Normalize text | `lower(col)` |
| Timestamp to date | `ts::DATE` |
| Shift time | `ts + INTERVAL 7 HOUR` |

## 8. Gaps in the source material

- The SQL handbook (Part 8 and the sections the slides cite) and the Session 4 slides aren't in the repo, so this guide comes from the lab files only.
- The `INSTRUCTOR_NOTES.md` file says not to upload the `solutions/` folder until after the session.
