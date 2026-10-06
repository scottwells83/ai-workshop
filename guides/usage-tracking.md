# Usage tracking and optimization

`usage-log.jsonl` in the Workshop root is the cross-project record. It contains counts and status metadata only; never store prompts, book contents, personal data, or other sensitive text.

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
