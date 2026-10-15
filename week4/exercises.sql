-- Session 4 suggested set. Four exercises, not logged and not required.
-- Answers are in solutions/exercises_solved.sql. Write yours first.

-- E1. Applications per campus.
--     For each campus, how many apply events and how many distinct users
--     applied. Handle the casing flaw. Sort by users, most first.


-- E2. The first thing each user did.
--     One row per user: user_id, the timestamp of their earliest event, and
--     what type it was. Do it with a window function, then again without one.


-- E3. Days on which applies outnumbered searches.
--     One row per day where the apply count is greater than the search count.
--     Include days with no events at all and say what your query does with them.


-- E4. Users who signed up in October and did nothing in the same week.
--     signup_ts is Pacific and occurred_ts is UTC. Say in a comment what you
--     did about that before you wrote the query.
