---
name: captain-hold-lifecycle
description: >-
  Agent-only policy for completing investigations and visual reviews without losing unresolved captain calls, and for closing what the captain owns with the captain's actual words.
  Load before treating an investigation, scout report, structured review, or Lavish review as complete, before ending a visual review that exposed a captain decision, when recording or routing the captain's answer, and on any RECORD DIVERGENCE line the wake drain prints.
user-invocable: false
metadata:
  internal: true
---

# Captain-hold lifecycle

A decision is simply a backlog task held for the captain through `bin/fm-captain-hold.sh hold`; its identity is the task id.
The agent performs the semantic inventory, because scripts must not infer captain calls from report prose, visual-review artifacts, terminal output, or chat.
`bin/fm-captain-hold.sh --help` owns command syntax, close modes, legacy identities, completion attestation, retries, and close ordering; `docs/captain-hold-lifecycle.md` owns the mechanism, including the captured-answer and board-reconcile seams.

## Completion gate

1. Read the complete investigation result, and finish the visual review, before declaring either complete.
2. Inventory only genuine unresolved questions that belong to the captain and that were discovered while producing, reading, presenting, or ending that work.
   Resolved findings, recommendations needing no captain choice, and prose that merely sounds decision-like create no held task.
3. Carry each one on a captain-held task in the authoritative backlog of the home that owns the originating work (run the commands in that `FM_HOME`; secondmate-owned work registers in that secondmate's backlog).
   - Prefer holding the work item the question gates; create a new task only when none exists.
   - The originating investigation or review is never its own inventory entry: hold a separate task and pass `--origin <origin-id>` so `complete` can check it.
   - Put the question and its options in the hold reason.
   - Keep one held task per genuine gate: a multi-question review is one held task pointing at its report, shown as exactly one board card consolidating its questions and options, never duplicate same-key cards.
   - `hold` is idempotent per task id; a question already held anywhere is never registered as a second row.
4. Run `bin/fm-captain-hold.sh complete` with every captain-held task id, or `--none` only when the reviewed surface leaves nothing waiting on the captain.
   A completed investigation and an ended visual review use this same command; no visual tool, Lavish included, owns a parallel completion policy.
   For a Lavish board-backed handoff, pass the reply through `bin/fm-procevent-lavish.sh arm --agent-reply-file` before appending the status.
5. Relay the choices as decisions from Bearings' Captain's Call under `AGENTS.md` section 9; never say "hold" in captain chat.
6. Confirm Bearings reflects each outcome: answered or reconciled-moot calls leave Captain's Call, released work resumes, active reconciliations stay held, and deferred calls sit in Charted Next with their date.
   Bearings reads structured state only and must never compensate by scraping reports, visual-review artifacts, terminal output, chat, or other prose.

## Closing a captain call

- Never close a captain-held task because the originating investigation completed, its report was archived, its review ended, or its task was torn down; cleanup keeps a held work row open with the deliverable recorded and returns it to the queue.
- Only `answer` with the captain's words, a channel that feeds `answers`, or an evidence-backed `reconcile close` may resolve it.
- `bin/fm-captain-hold.sh answer` records the captain's exact words and closes a question-shaped call; `--release` frees a captain-gated work item to proceed.
- A merge approval uses `--release`; cleanup closes the work only after it lands and records what shipped, because closing at approval would claim completion before the work ships.
- When the answer changes what a task must build, follow `AGENTS.md` section 7's mid-task ask rule.
- "Later" is an answer: re-hold with `bin/fm-captain-hold.sh hold <id> --reason "<reason>" --until <date>` rather than leaving a live-looking card or fabricating a closure.
- A captain-held task closed outside this owner leaves no durable answer, so the completion gate keeps failing until `answer` records what the captain actually said.

## Keyed answers and reconcile

- `bin/fm-captain-hold.sh answers` is the one owner of "a keyed answer resolves its matching captain-held task"; every channel feeds it the task id and answer, and no channel maps keys, records a decision, or resolves anything itself.
- Chat feeds it through `bin/fm-send.sh --resolve-key`; a captured-answer source feeds it once bound with `bin/fm-captain-hold.sh bind <source-id>`, which must run before arming the source, with each structured question keyed by the held task's id.
- An unbound source, or a key naming no captain-held task, feeds nothing: the answer is still captured and firstmate still woken, and closing falls back to `answer`.
- `reconcile` is reserved and closes nothing: it means "go re-check reality", never "the captain answered", so every channel's intake refuses it as an answer.
- A board Reconcile selection files a durable request that you work off in the turn that receives it: `reconcile close <id> --evidence-file <path>` records the evidence and closes a moot call, and `reconcile note <id> --note-file <path>` annotates a still-active call and leaves it held.
  Both refuse unless the board-created request is pending, so neither is a standalone way to mutate a captain call; `reconcile list` names every outstanding request.
- Never use `answer` for an evidence-only moot call: `answer` records what the captain said, and `reconcile close` records verified evidence.
- A normal answer also retires any pending request; a retirement failure fails the command without reversing the durable answer, and `reconcile list` keeps the request visible for retry.
- A remote-secondmate card whose task is absent from the main backlog stays announced but cannot create a main-home request; owner-aware routing is a separate follow-up.

## RECORD DIVERGENCE

A captain call can be written twice - as the keyed status decision and as the captain-held backlog task - and the two can disagree silently.
`bin/fm-captain-hold.sh diverged` reports that and the wake drain prints it as `RECORD DIVERGENCE`; it closes nothing, because a wrongly closed captain call leaves review entirely.
Read it as "these two records disagree", never as "the captain ruled and someone forgot to file it": a call can dissolve because its premise was false, or prove to be a question of fact rather than the captain's to answer.
Reconcile with what actually happened: `answer` when the captain's own words exist to record, or a fresh `needs-decision` line re-opening the status decision when the resolution was not the captain's word.
The absence of a routed work item is not a divergence and the guard never requires one: when the decision is the deliverable there is nothing to route.
