# Session 4 lab: the event log

Ten minutes in class. Everything else here is the suggested set.

## Build the log

    pip install duckdb
    python make_event_log.py

That writes `events.duckdb` and three CSVs beside it. The generator is seeded,
so everybody in the room gets the same log.

| Table | One row is | Columns |
|---|---|---|
| `users` | A person who signed up | `user_id`, `signup_ts`, `campus`, `program` |
| `events` | One thing a person did | `event_id`, `user_id`, `event_type`, `occurred_ts`, `platform` |
| `calendar` | One day in October, whether or not anything happened | `day` |

400 users and about 12,000 events across October 2026.

## Open it

    duckdb events.duckdb

Or from Python:

    import duckdb
    con = duckdb.connect("events.duckdb")
    con.sql("SELECT COUNT(*) FROM events").show()

If you were given the CSVs instead, DuckDB reads them where they sit:

    SELECT COUNT(*) FROM 'events.csv';

## Files

| File | What it is |
|---|---|
| `make_event_log.py` | Builds the log. Run once |
| `lab_queries.sql` | The six lab queries. Query 4 is the point |
| `exercises.sql` | The suggested set, four questions, no answers |
| `solutions/` | Answers. Open after you have written your own |

## The log is deliberately flawed

Four things are wrong with it, and finding them is Part 8 of the SQL handbook.
Do not fix the generator. These flaws are the material.
