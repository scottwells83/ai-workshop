# Parallel job manifest

Create one self-contained five-part brief per job in `briefs/`. Then edit the project's `jobs.json`:

```json
{
  "parallel": 2,
  "jobs": [
    {"id": "draft-a", "model": "local-drafter", "brief": "draft-a.txt", "category": "drafting"},
    {"id": "draft-b", "model": "local-drafter", "brief": "draft-b.txt", "category": "drafting"},
    {"id": "format", "model": "local-worker", "brief": "format.txt", "category": "extraction", "depends_on": ["draft-a", "draft-b"]}
  ]
}
```

Dependencies control order. The runner appends completed dependency outputs as reference data to the dependent brief. The Manager must still make the five-part brief self-contained for the task and ensure the combined context fits the local model. This process applies whenever a new project begins and whenever an existing project resumes. Inspect its current manifest and project log, preserve useful earlier jobs/history, and add assignments for the current phase. Before running, make sure every listed job is a real bounded assignment; if none fits the current phase, note why in `project.md` instead of adding filler. Run `doctor` if availability is uncertain, then run the project. Check that each expected job appears as completed in `run-report.json` and has a nonempty output. `run-history.jsonl` preserves each execution and Ollama's prompt/evaluation token counts and duration. The Workshop-root `usage-log.jsonl` collects job usage across projects and session proxies for Work and Codex; see `guides/usage-tracking.md`. These are execution records, not QA results: review every output against its brief and sources, then record the exact run's acceptance, rejection, or rework. `--force` archives an earlier output before replacing it.
