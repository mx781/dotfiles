# P1 validation workflow

When running `smoke-test.sh` against a VM or remote target:

1. Treat `~/p1-smoke-artifacts/` on the target as temporary staging only.
   Copy the complete timestamped artifact directory to a host-side results
   directory before reporting completion.
2. Open `report.md` from that host-side copy.  Inspect every screenshot listed
   in its **Visual review** section with the image viewer; do not treat a
   successful `maim` command as visual validation.
3. Report both the automated summary and the outcome of the screenshot review.
   Investigate missing, blank, stale, or visibly incorrect screenshots before
   declaring the provisioning test successful.
4. Do not capture, open, or report Gopass entries, private keys, or ordinary
   clipboard contents.  XSecureLock and Clipmenu retain explicit manual checks
   because safely automating their interactive UI would violate this boundary.

# Handing over playbook commands

P1's play declares `become: true`, so it escalates on its own.  When giving the
user a command to run, write it for their own interactive terminal:

```sh
cd ~/hub/dotfiles/provisioning/p1
ansible-playbook -i inventory/localhost.ini site.yml \
    -e target_user=maksis -e dotfiles_repo="$HOME/hub/dotfiles" \
    --ask-become-pass --tags apps
```

1. Always pass `--ask-become-pass`.  `ansible.cfg` sets `become_ask_pass =
   False`, so without it the run dies on the first escalated task.
2. Never prefix the command with `sudo`; a non-interactive `sudo` cannot read a
   password and fails immediately.
3. Never wrap the command in `script -qefc` or hand it over for Claude Code's
   `!` prefix.  That path has no interactive stdio, which is exactly what a
   password prompt needs.  The user runs these themselves.
4. Scope reruns with `--tags`; the `always`-tagged pre_tasks still run.  Leave
   the cached archives under `/var/cache/p1-*` in place so `get_url` skips the
   large downloads.
