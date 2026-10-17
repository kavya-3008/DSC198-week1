# SQL from zero, using the event log

You need no SQL background. Every command is explained, in the order you will meet it. All the numbers below come from the real `events.duckdb` in this folder, so you can run each example and check yourself.

How to run an example: open a terminal in `week4/`, type `duckdb events.duckdb`, paste the query, and press Enter. Type `.quit` to leave.

---

## Part 1. What SQL is

A **database** stores data in **tables**. A table is a grid: each **column** is one kind of fact, and each **row** is one thing.

**SQL** is a language for asking questions about those tables. You don't tell the computer *how* to find the answer step by step. You describe *what* you want, and the database works out how.

Our database has three tables.

**`users`** (one row = one person who signed up, 400 rows)

| user_id | signup_ts | campus | program |
|---|---|---|---|
| 5 | 2026-10-20 10:59:00 | UCSD | ECON |
| 7 | 2026-10-14 20:08:00 | UCSD | MATH |

**`events`** (one row = one thing a person did, 12,316 rows)

| event_id | user_id | event_type | occurred_ts | platform |
|---|---|---|---|---|
| 8886 | 243 | view | 2026-10-23 07:53:20 | android |
| 4314 | 361 | view | 2026-10-11 07:30:13 | ios |

**`calendar`** (one row = one day in October, 31 rows). It has one column, `day`.

`user_id` appears in both `users` and `events`. That shared column is how the two tables connect: event 8886 was done by user 243.

---

## Part 2. Look at the data

```sql
SELECT * FROM users LIMIT 5;
```

| Piece | Meaning |
|---|---|
| `SELECT` | "Show me these columns." |
| `*` | "All of them." |
| `FROM users` | "Out of the table called `users`." |
| `LIMIT 5` | "Stop after 5 rows." Without it you would print every row. |
| `;` | "This question is finished." Always end with it. |

Other useful commands, typed on their own line (no semicolon):
- `SHOW TABLES;` lists the tables.
- `.schema events` shows the columns and their types.
- `.quit` leaves the program.

**Why `SELECT` and `FROM` appear in the order they do** is explained in Part 4. First, more tools.

---

## Part 3. The building blocks, one at a time

### 3.1 Choose columns
```sql
SELECT user_id, campus FROM users LIMIT 3;
```
Listing column names, separated by commas, shows only those.

### 3.2 Filter rows with WHERE
```sql
SELECT * FROM users WHERE campus = 'UCSD';
```
`WHERE` keeps only the rows where the condition is true. Text goes in single quotes. This returns the 104 UCSD users. Other conditions you can use: `>`, `<`, `>=`, `<=`, `<>` (not equal), `AND`, `OR`.

### 3.3 Count rows with COUNT
```sql
SELECT COUNT(*) FROM users;
```
Returns `400`. `COUNT(*)` means "how many rows." Add a `WHERE` to count only some:
```sql
SELECT COUNT(*) FROM users WHERE campus = 'UCSD';
```
Returns `104`.

`COUNT` is an **aggregate function**: it takes many rows and returns one number. Others are `SUM`, `AVG`, `MIN`, `MAX`.

### 3.4 Make groups with GROUP BY
"How many users per campus?" That means one count per campus, not one count total:
```sql
SELECT campus, COUNT(*) AS n
FROM users
GROUP BY campus;
```
`GROUP BY campus` sorts rows into piles, one pile per campus value. `COUNT(*)` then counts each pile separately. Result:

| campus | n |
|---|---|
| UCI | 114 |
| UCSD | 104 |
| UCLA | 103 |
| UCD | 79 |

`AS n` is just a nickname for the column. It changes only the label.

**Rule:** any column in `SELECT` must either be in `GROUP BY` or be inside an aggregate like `COUNT`.

### 3.5 Sort with ORDER BY
```sql
SELECT campus, COUNT(*) AS n FROM users GROUP BY campus ORDER BY n DESC;
```
`ORDER BY n` sorts by that column. `DESC` is largest first. Leave it off for smallest first (`ASC`). Without `ORDER BY`, the row order is not guaranteed.

### 3.6 Count different people with DISTINCT
`COUNT(*)` counts rows. `COUNT(DISTINCT user_id)` counts different values, so one person with ten events counts once.
```sql
SELECT COUNT(*) AS events, COUNT(DISTINCT user_id) AS people FROM events;
```
Use `DISTINCT` whenever you mean "how many people" and the table has several rows per person.

### 3.7 Filter groups with HAVING
"Which users did at least 3 applies?" You need to count first, then filter on the count:
```sql
SELECT user_id, COUNT(*) AS applies
FROM events
WHERE lower(event_type) = 'apply'
GROUP BY user_id
HAVING COUNT(*) >= 3;
```
- `WHERE` filters **rows** before grouping.
- `HAVING` filters **groups** after grouping.
- `lower(event_type)` turns text to lowercase, because the data contains `apply`, `Apply`, and `APPLY`.

### 3.8 Combine tables with JOIN
Events don't say which campus a user is from. Users do. To count events per campus, connect the two tables:
```sql
SELECT u.campus, COUNT(*) AS events
FROM events e
JOIN users u ON u.user_id = e.user_id
GROUP BY u.campus;
```
- `events e` gives the table a short nickname `e`. `users u` does the same.
- `JOIN users u ON u.user_id = e.user_id` means: "for each event, find the user row with the matching `user_id` and glue them together."
- Now every row has both event columns and user columns, so `u.campus` works. Writing `u.` or `e.` says which table a column comes from.

A plain `JOIN` keeps only rows that found a match. Our `events` has 12,316 rows, but this join keeps only 12,076, because 240 events have no `user_id` (it is NULL) and match nobody. They silently vanish.

### 3.9 Keep unmatched rows with LEFT JOIN
`LEFT JOIN` keeps **every** row from the left table, even if nothing matches. The missing side is filled with `NULL`.
```sql
SELECT c.day, COUNT(DISTINCT e.user_id) AS users
FROM calendar c
LEFT JOIN events e ON e.occurred_ts::DATE = c.day
GROUP BY c.day
ORDER BY c.day;
```
`occurred_ts::DATE` cuts the timestamp down to just its date. Oct 12 has no events, so it would vanish from a plain `GROUP BY` on `events`, giving 30 rows. Starting from `calendar` and using `LEFT JOIN` keeps it, with a count of 0, giving all 31.

### 3.10 NULL
`NULL` means "unknown or missing." It is not zero and not an empty string.
- `x = NULL` is never true. Use `x IS NULL` or `x IS NOT NULL`.
- `COUNT(col)` skips NULLs, while `COUNT(*)` counts every row.

### 3.11 Name a step with WITH
A **CTE** (common table expression) gives a name to a mini-query so the main query reads in steps:
```sql
WITH clean AS (
  SELECT DISTINCT event_id, user_id, lower(event_type) AS event_type, occurred_ts
  FROM events
)
SELECT event_type, COUNT(*) FROM clean GROUP BY event_type;
```
`clean` works like a temporary table that exists only for this query. `DISTINCT` removes duplicate rows.

---

## Part 4. Why we write the lines in a different order than they run

This is the most confusing part of SQL, so here is the full explanation.

**SQL is written like an English request, but executed like a recipe.**

You write: *"Show me the campus and the count, from the users, only UCSD, grouped by campus, sorted."* That's a natural sentence, so SQL makes you state what you want to *see* first (`SELECT`).

But the database can't produce output until it knows where the data comes from and which rows survive. So it works in a different order:

| Run order | Clause | What the database is doing |
|---|---|---|
| 1 | `FROM` / `JOIN` | Get the table(s), and glue them together |
| 2 | `WHERE` | Throw away rows that fail the condition |
| 3 | `GROUP BY` | Sort the surviving rows into piles |
| 4 | `HAVING` | Throw away piles that fail the condition |
| 5 | `SELECT` | Now compute the columns and counts to show |
| 6 | `ORDER BY` | Sort the final result |
| 7 | `LIMIT` | Cut to the first N rows |

**Written order**, which you must always follow: `SELECT`, `FROM`, `JOIN`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `LIMIT`.

**Analogy:** ordering at a restaurant. You say what you want first ("a salad"), but the kitchen starts with ingredients (`FROM`), picks the good ones (`WHERE`), prepares them (`GROUP BY`), and plates the dish last (`SELECT`).

### Consequences you can test
1. **An aggregate can't go in `WHERE`.** `WHERE COUNT(*) >= 3` fails, because `WHERE` runs at step 2 and the piles (and their counts) don't exist until step 3. That's why `HAVING` exists: it runs after the piles are made.
2. **A nickname defined in `SELECT` may not work earlier.** `AS n` is created at step 5, so `WHERE n > 5` can't use it. (`ORDER BY n` can, because it runs at step 6. DuckDB also lets `GROUP BY` use nicknames as a convenience.)
3. **`ON` versus `WHERE` in a `LEFT JOIN`.** `ON` decides which rows match during the join, at step 1. `WHERE` filters the already-joined result at step 2. Putting a condition on the right table in `WHERE` can remove the unmatched rows a `LEFT JOIN` was supposed to keep.

A good mental trick: when a query surprises you, read it in **run order**, not written order.

---

## Part 5. Finding "who never did X" (the lesson of lab query 4)

Question: which users never applied?

**Attempt 1, `NOT IN`:**
```sql
SELECT user_id FROM users
WHERE user_id NOT IN (SELECT user_id FROM events WHERE lower(event_type) = 'apply');
```
It returns **0 rows**. The inner query returns a list of user ids, and that list contains a `NULL` (the 240 events with no user). SQL can't say a number is "not in" a list that might contain an unknown value, so `NOT IN` is never true for anyone. The query is silently wrong.

**Attempt 2, the anti-join:**
```sql
SELECT u.user_id
FROM users u
LEFT JOIN events e
  ON e.user_id = u.user_id AND lower(e.event_type) = 'apply'
WHERE e.user_id IS NULL;
```
This returns **103 users**. Reading it in run order:
1. Take every user, and try to attach their apply events.
2. Users with no apply events still stay (that's `LEFT JOIN`), with `NULL` on the event side.
3. Keep only rows where the event side is `NULL`, meaning no apply was found.

Note that the `apply` condition sits in `ON`, not `WHERE`. If it were in `WHERE`, every row without an apply would be thrown out, and the query would return nothing useful.

---

## Part 6. The four traps hidden in this data

Always check data before trusting a number.

| Trap | How to spot it | What goes wrong |
|---|---|---|
| Duplicate rows | `SELECT COUNT(*), COUNT(DISTINCT event_id) FROM events;` gives 12,316 and 12,136 | counts are inflated by 180 |
| Mixed capital letters | `SELECT event_type, COUNT(*) FROM events GROUP BY event_type;` gives 7 rows for 4 types | `= 'apply'` misses `Apply` and `APPLY` |
| NULL `user_id` | `SELECT COUNT(*) FROM events WHERE user_id IS NULL;` gives 240 | `NOT IN` returns nothing, and joins drop them |
| Different timezones | `occurred_ts` is UTC, `signup_ts` is Pacific | day comparisons are off by up to 8 hours |

---

## Part 7. How to write your own query

Work through these questions *before* typing:

1. **What is one row of my answer?** (a user? a day? a campus?) That decides what goes in `GROUP BY`.
2. **Which table holds what I'm counting?** That goes in `FROM`.
3. **Do I need another table?** If yes, `JOIN` on the shared column.
4. **Do I need rows that match nothing?** If yes, `LEFT JOIN` starting from the complete table.
5. **Am I filtering rows or groups?** Rows go in `WHERE`, groups go in `HAVING`.
6. **What could be NULL, duplicated, or written inconsistently?**
7. **Guess the number of rows I expect.** Then run it and compare.

Then build in layers, running after each step:
```sql
SELECT * FROM events LIMIT 5;                         -- 1. look
SELECT * FROM events WHERE lower(event_type)='apply'; -- 2. filter
-- 3. add the join, 4. add GROUP BY and COUNT, 5. add ORDER BY
```
If something looks wrong, check the **row count** first, then the first five rows, then the join condition.

---

## Part 8. Teaching this to someone else

You can cover the material in about 90 minutes if you follow this order, and each person predicts the answer on paper before running anything:

1. Look at the tables (Part 2): 5 minutes.
2. Filter and count (3.1 to 3.3): 10 minutes.
3. Group and sort (3.4 to 3.6): 15 minutes.
4. `HAVING`, and the run-order table (3.7 and Part 4): 15 minutes. Have them put `COUNT(*)` in `WHERE` and read the error.
5. `JOIN` and `LEFT JOIN`, including the missing Oct 12 (3.8, 3.9): 20 minutes.
6. `NOT IN` versus the anti-join (Part 5): 15 minutes. This is the main lesson.
7. The four traps and CTEs (Part 6, 3.11): 10 minutes.

Practice problems, with answers in `solutions/` (try first, then check): `exercises.sql` E1 to E4.

---

## Quick reference

| I want to... | Write |
|---|---|
| See some rows | `SELECT * FROM t LIMIT 5;` |
| Filter rows | `WHERE col = 'x'` |
| Count rows | `COUNT(*)` |
| Count different people | `COUNT(DISTINCT user_id)` |
| One count per category | `GROUP BY category` |
| Filter on a count | `HAVING COUNT(*) >= 3` |
| Largest first | `ORDER BY n DESC` |
| Combine two tables | `JOIN b ON a.id = b.id` |
| Keep unmatched rows | `LEFT JOIN` |
| Find who never did X | `LEFT JOIN ... WHERE right.key IS NULL` |
| Check for missing values | `IS NULL` / `IS NOT NULL` |
| Ignore capitalization | `lower(col)` |
| Timestamp to date | `ts::DATE` |
| Name a step | `WITH name AS (...)` |
