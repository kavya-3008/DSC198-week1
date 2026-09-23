# Session 1 lab: your practice repository

Twenty minutes. You leave with a private repository, one merged pull request,
and a folder per week to put solutions in.

## Files here

| File | What it is |
|---|---|
| `hello.py` | The trivial function you push in the lab |
| `test_hello.py` | Its test. It passes |
| `gitignore.template` | Rename to `.gitignore` in your repository |

## The lab

1. Create a private repository on GitHub named `dsc198-practice`.
2. Clone it, then copy the three files here into it. Rename the template:

        git clone git@github.com:YOU/dsc198-practice.git
        cd dsc198-practice
        cp .../gitignore.template .gitignore
        mkdir -p week1 week2 week3 week4 week5

3. Write a README with one line saying what the repository is for.
4. Branch, commit, push:

        git switch -c add-hello
        git add .
        git commit -m "Add hello and its test"
        git push -u origin add-hello

5. Open a pull request. Request review from the person on your left.
6. Review theirs. Leave one comment. Approve.
7. Merge yours, then:

        git switch main
        git pull

`git log --oneline --graph` should show the merge.

## If the push is rejected

You have no SSH key on this machine, or the key is not on your GitHub account.
Generate one and add it:

    ssh-keygen -t ed25519 -C "your@email"
    cat ~/.ssh/id_ed25519.pub

Paste that into GitHub, Settings, SSH and GPG keys. Then push again.
