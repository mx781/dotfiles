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
