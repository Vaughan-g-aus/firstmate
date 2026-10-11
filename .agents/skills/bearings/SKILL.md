---
name: bearings
description: >-
  Generate a "pick up where I left off" fleet digest from firstmate's live fleet state.
  Use when the captain invokes /bearings or asks for a bearings report, morning brief, status report, catch-up, "where did I leave off", or "what's in the works".
  Plain /bearings is chat-only, /bearings file also writes the dated data/status-report-<YYYY-MM-DD>.md artifact, and /bearings lavish also builds and arms the interactive fleet board; live PR enrichment is opt-in and composes with every mode.
  Also use on a contributions check wake or when filing work linked to an upstream issue, and on a procevent lavish wake whose source id matches the stable bearings board path.
user-invocable: true
metadata:
  internal: true
---

# bearings

Produce a complete current fleet snapshot the captain can resume from in one read.

- **Contribution wake or linked-issue filing:** read [`references/contributions.md`](references/contributions.md) and follow it instead of the digest procedure.
- **`/bearings lavish`, or a `procevent lavish` wake whose source id equals `bin/fm-procevent-lavish.sh source-id "$(bin/fm-bearings-board.sh path)"`:** also read [`references/lavish-board.md`](references/lavish-board.md), which owns the board payload rules, board-wake routing, and the captain-decided merge-click safeguards.
  A board "Merge now" is never acted on without those safeguards.

## Read-only invocation

A digest or build invocation changes nothing beyond observational remote-ledger cache refreshes, durable local per-target reconcile-notify requests, and the explicit per-mode artifacts: the dated report in file mode, and in lavish mode the board file plus the answer binding and source registration `bin/fm-bearings-board.sh build` records through their owners.
During it, never tear down a task, merge a PR, dispatch queued work, steer a worker, answer a decision, clean up work, or mutate any other `state/`, `data/`, backlog, or task state.
If the gathered state suggests an action, name it in its section and leave it to the normal lifecycle and configured authority.
Board answers are acted on later, under `references/lavish-board.md`'s guarded board-wake authority.

## Modes

- Plain `/bearings`: fresh snapshot, four-section chat digest; never creates, deletes, reads, or replaces `data/status-report-<YYYY-MM-DD>.md`.
- `/bearings file`: fresh snapshot, replace today's report from scratch, then the chat digest with the report path or link.
- `/bearings lavish`: fresh snapshot, rebuild and arm the board, then the chat digest with the board URL.
- `file` and `lavish` are only explicit standalone options in the slash command; natural-language asks such as "write a report", "save this", "persist it", "make a file", or "make a board" do not select them.
- When the captain asks to include PRs (for example `/bearings include PRs`, which stays chat-only), pass the snapshot's `--include-prs` opt-in, and only then; it composes with `file` and `lavish`.

## Procedure

1. **Gather with one command.**
   Run `snapshot=$(bin/fm-bearings-snapshot.sh --json)` at invocation time; its header and `--help` own fields, bounds, opt-ins, and output.
   It is the single fleet-state source: never add a second reader, parser, status-tail interpretation, visible-session recap, ad-hoc project probe, or ad-hoc `gh-axi`/`gh` query, and never scrape reports, visual-review artifacts, raw status tails, or conversation history to supplement it.
   The default bounds concurrent remote-ledger reads for registered remote homes under one budget and may refresh the parent-side cache; registered owned contributions come from the cached `contributions` projection regardless of `--include-prs`.
   For registered secondmates use the snapshot's structured-home classification and provenance; a parent event or bounded terminal contradiction is fallback evidence, never authority over readable structured home state.
2. **Record reconcile notifications for homes whose books disagree.**
   When a secondmate home's `invalidity` is `orphan_in_flight`, `unowned_current`, or `terminal_in_flight`, run `printf '%s\n' "$snapshot" | bin/fm-secondmate-reconcile.sh request --snapshot -` right after gathering.
   It only records one local one-shot request per mismatched target (its header owns coalescing, durability, retries, the four-hour cooldown, and retirement); the supervision loop delivers later.
   Keep composing; if request publication fails, report that durability blocker and never fall back to an inline send.
   Never edit another home's backlog or metadata, and never expect or wait on a reply.
3. **Compose the chat digest** under the contract below; your judgment is limited to ranking the snapshot's facts by current importance and writing scannable prose.
   Plain mode stops here.
4. **File mode only:** write the full report to `data/status-report-<YYYY-MM-DD>.md` (delete today's file first and create it from scratch; this is file mode's only write).
   Never read an earlier `data/status-report-*.md` to decide what to omit, include, call changed, or call current.
   Title it `# Bearings - <day> <YYYY-MM-DD>` ("Morning status" only when the captain asks for a morning brief) with two or three framing sentences, then the same four sections with the detail chat omits: each open decision with its options from the structured record, PRs ready to merge, credentials or logins needed, current state of each live direct report with pickup pointers (`data/<id>/report.md`, `.lavish/*.html`), and each queued or gated item's blocker, date, age, or integrity reason.
   Then return the chat digest with the report path or link and no fifth section; offer `/bearings lavish` only after the digest is ready and only when the report has enough structure to deserve one.

## Chat-response contract

This skill is the one owner of the `/bearings` chat format.
Every response renders exactly these four sections in this order, each always present with its empty-state sentence, and nothing else structural (no At Anchor section):

1. **Captain's Call** - only unsuppressed items needing the captain's own action now: a decision, a PR to approve or merge, a credential or login, or a blocker only the captain can clear.
   Include `contributions.captain` rows, deduplicated against any live captain hold or merge call for the same item; show the other contribution actors only as counts beside checked/known coverage, and disclose nonzero `captain_omitted`, `unmeasured_homes`, stale verdicts, and checks with no verdict.
   Say "Nothing needs your action right now" only when `contributions.proven_clear` is true and the decision set is empty; otherwise an empty section says no decision is recorded and gives the checked/known count, and a missing coverage field is unverified.
2. **Recently Landed** - the bounded current recent-completions baseline across the main fleet and every registered secondmate home (merged PRs, completed scouts, finished local-only merges), rendered in full every run even if shown before.
   Empty: "No recent completions are in the current baseline."
3. **Underway** - one line of current state per live direct report.
   Empty: "Nothing is underway."
4. **Charted Next** - queued or gated work with its blocker, date, or age; deferred, blocked, or aged captain-hold gates; and action-free fleet-integrity warnings.
   Empty: "Nothing is queued."

Placement rules:

- A captain hold sits in exactly one bucket, assigned by the snapshot from structured fields only (never hold-reason or body prose): `blocked` if any blocker is unresolved, else `dated` while `hold_until` is in the future, else `aged` once an undated hold reaches the configured age threshold, else `live`.
  `live` goes in Captain's Call; `blocked`, `dated`, and `aged` are disclosed Charted Next gates stating their structured reason.
  `--all-decisions` reveals every hold in the bounded snapshot and moves those gates into Captain's Call; aging is only a presentation safety net, and re-holding with `--until` remains the durable deferral.
- Underway reports active work independently, so an actively worked captain-held task may appear there and in its one decision bucket.
- A queued item becomes next work only when its blocker is gone and its time or date gate has arrived; until then it stays queued with its reason.
- Action-free items never enter Captain's Call: working or validating tasks, items blocked on another task or a date, landed work, a completed scout's report pointer, a declared `paused:` external wait, and a bare recorded PR with no merge-ready signal.
- The `(main-inventory)` and `(return-catchup)` gates, an unavailable secondmate home, and a readable home whose `invalidity` reports a backlog-vs-metadata mismatch are action-free warning rows under Charted Next with their `omitted` disclosure; never invent an Underway row from backlog-only state.
  Fleet action during an open return catch-up still waits for `bin/fm-afk-return.sh check`.
- A secondmate home can feed several sections: each active child is an Underway row whatever the home-level `bearings_state`, its live captain hold is Captain's Call, and its queued or external holds stay in Charted Next.
  A home-level row is not an Underway unit: `externally_held` belongs in Charted Next, and `unknown` there as an unavailable-state gate unless its reason needs the captain.
  Never hide a home's active children, separately projected decisions, landed records, or gates because the home has an open hold, is `partial-structured`, reports `unknown`, or reports an inventory mismatch.

Style rules:

- Every digest and report is a complete current snapshot, never a delta against a prior report.
- Follow `AGENTS.md` section 9 with one scannable line per item, and put the required direct address to the captain inside one item or empty-state sentence.
- Every PR appears as its full `https://...` URL; `#number` is allowed only as a back-reference after the full URL appeared in the same digest.
- Detailed decisions, plans, full gate reasons, and evidence stay out of chat: file mode puts them in the report, and lavish mode puts only payload-backed detail on the board.
- Put the file-mode report path or the lavish board URL inside the four-section digest, never under another heading.
- The file-mode report is a private captain-facing artifact in gitignored `data/`, so it may name task ids, PR URLs, and repos; keep it organized rather than a raw dump, and never include PHI or secret values.
