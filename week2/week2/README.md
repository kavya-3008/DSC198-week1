# Session 2 lab: reading a failure

Two parts. First you watch a test fail and read the report. Then you review
somebody else's code.

## Files here

| File | What it is |
|---|---|
| `two_sum.py` | A solution with one deliberate bug |
| `test_two_sum.py` | Four tests. Three pass |
| `review_checklist.md` | The three comments you have to leave in part two |

## Part one, the failure

    pip install pytest
    pytest -q

One test fails. Before you fix anything, answer these out loud:

1. Which test failed, and what were the inputs?
2. What did the code return, and what did the test expect?
3. Which line of `two_sum.py` produced the wrong value?

Then fix it and run again. `pytest -q` prints `4 passed`.

    pytest -q                  # quiet
    pytest -v                  # one line per test
    pytest -k empty            # only tests with empty in the name
    pytest -x                  # stop at the first failure

## Part two, the review

Swap repositories with your partner. Open their pull request, read the whole
file before commenting, then leave the three comments in `review_checklist.md`.
