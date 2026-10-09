# Usage tracking and optimization

`usage-log.jsonl` in the Workshop root is the cross-project record. It contains counts and status metadata only; never store prompts, book contents, personal data, or other sensitive text.

## Workshop-first routing

The initiating assistant checks local access and the automatic-handoff setting before substantive work in its own service. A successful handoff records an `entered_workshop` routing event automatically, tagged by the `--origin` assistant label. The launcher also records when automatic handoff is disabled. If the local Manager later fails or uses a configured outside AI provider, those outcomes are recorded separately. These events show routing behavior, not task quality or saved commercial tokens.

When a local-capable assistant cannot use Workshop, it records the reason without the user's prompt:

```text
workshop usage route --surface codex --outcome unavailable --reason local_capability_gap --capability repository-engineering
```

Other reason codes include `no_local_access`, `workshop_not_installed`, `auto_handoff_disabled`, `launcher_failed`, `manager_error`, `outside_provider_unconfigured`, `outside_service_required`, `user_preference`, and `unknown`. Use short lowercase labels for `--surface` and `--capability`; do not include user names, project titles, prompt text, or file paths. `--project <slug>` is optional when an existing project is involved. `workshop usage summary` now includes routing counts by outcome, unavailable reason, capability, and initiating surface so repeated gaps can guide product changes.

A cloud-only assistant cannot write `usage-log.jsonl`. It should state a compact `AIW routing gap: surface=<assistant> reason=no_local_access capability=local-execution; not logged` notice. A later local-capable session may record that event with `workshop usage route`; never claim it was logged before then. The initiating service may consume tokens for the initial message and routing call. Workshop-first routing can reduce subsequent use, but five-hour account limits are not measured by this log and no particular reduction is guaranteed.

## Daily task share

The local app records one `task_outcome` when it responds to a request, classifying the executor as `workshop` or `hybrid` if it used a configured outside AI provider. A local-capable assistant that completes a request outside Workshop should record one outcome after answering:

```text
workshop usage task --surface codex --executor external --status responded --capability repository-engineering
```

Use `--status failed` if no response was delivered. Do not count a local draft or a successful handoff as a completed response. `workshop usage summary --day YYYY-MM-DD` filters to one calendar day in the computer's local time zone and reports counts and percentages for `workshop`, `hybrid`, `external`, and `unknown` among **logged responses**. It also reports failed requests and routing gaps. A response is evidence that a service answered, not that the answer passed QA. Cloud-only work and any other unlogged requests are excluded; the report must show that coverage limitation and must not call these percentages a share of every task across all platforms.

## Automatic local records

Every `workshop run <project>` appends one record per job with project and job IDs, model, optional workload category, execution status, Ollama prompt/response token counts, and elapsed time. The project's `run-report.json` is the latest run; `run-history.jsonl` retains prior runs. A manifest entry alone is not counted as work performed. Use short stable categories such as `analysis`, `coding`, `comparison`, `drafting`, `extraction`, `review`, or `other` so later summaries compare similar work.

After Manager QA, add the outcome and link it to the exact run timestamp shown in `run-report.json`:

```text
workshop usage qa --project paperwhite-mac-e-reader --job release-notes-draft --status accepted --run-at 2026-10-06T10:45:25.935146+00:00 --review-seconds 90
```

Use `accepted` when the output is suitable after review, `rework` when a concrete retry/correction was needed, and `rejected` when the result remains materially unreliable or unsuitable. Add a short non-sensitive `--note` describing the reason. Supply `--review-seconds` only when you measured the time spent reviewing that exact run; leave it absent when unknown.

## Work and Codex records

At the end of each project session in ChatGPT Work or Codex, add one record:

```text
workshop usage add --project paperwhite-mac-e-reader --surface codex --task "PaperLike implementation and review" --messages 13 --visible-words 3703 --metric-source transcript-count
```

If the product supplies actual per-session token counts, include both `--input-tokens` and `--output-tokens` and set `--metric-source app-reported`. If token counts are unavailable, leave them out. Message and visible-word counts are conversation-size proxies, not token or cost estimates. When no reliable count is available, use `--metric-source unavailable`.

## Review

Run `workshop usage summary` for all projects, or filter with `--project <slug>` and/or `--since YYYY-MM-DD`. The report separates exact token counts from transcript proxies, groups local jobs by category, and shows QA outcomes plus measured review time where available. A `null` review-time value means it was not measured, not zero. Use `usage-analyst` to interpret a sufficient set of dated records: compare comparable measures, identify rework and elapsed-time patterns, suggest suitable local assignments, and propose new specialists only when the records show a frequent, distinct workload. Treat its recommendations as hypotheses for Manager review.

ChatGPT Work/Codex per-thread token usage may be unavailable. Do not infer it from account-wide rate limits, message counts, visible words, or character counts. Keep unknown token fields null so later reviews can distinguish missing measurements from zero use.
