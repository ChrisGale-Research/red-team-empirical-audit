# Model versions, access routes and dates

This file records how each model in the review panel was accessed, under which
identifier and on which date. Run-by-run outcomes, including failed runs, are
in `reviewer_outputs/README.md`.

## Open-weight panel (scripted, `triveritas_pregabalin.py`)

| Model | Identifier as called | Access route | Runs returning a review | Dates |
|---|---|---|---|---|
| DeepSeek-R1 | `deepseek-reasoner` | DeepSeek API (developer-hosted) | 113433, 114902, 120617, 121155, 124625 (truncated before the RECOMMENDATION line in every run) | 22 June 2026 |
| Qwen3-235B | `qwen/qwen3-235b-a22b` | OpenRouter | 113433, 114902, 120617, 121155, 124625 | 22 June 2026 |
| Llama-3.1-70B | `meta-llama/llama-3.1-70b-instruct` | OpenRouter | 124625 | 22 June 2026 |

Run identifiers are the timestamps in `reviewer_outputs/triveritas_results_<YYYYMMDD_HHMMSS>.md`
(local time, New Zealand). None of the open-weight models was run locally for
these reviews; an attempt to run Llama locally was abandoned on hardware
grounds.

## Cold reads (interactive, by hand)

| Model | Interface | Version | Date run | Retained |
|---|---|---|---|---|
| Gemini (read 1) | gemini.google.com | not recorded | not recorded | Yes: `reviewer_outputs/cold_reads/gemini_cold_read_1.md` |
| Gemini (read 2) | gemini.google.com | not recorded | not recorded | Yes: `reviewer_outputs/cold_reads/gemini_cold_read_2.md` |
| Grok | grok.com (web interface) | not recorded | not recorded | **No.** Not retained and not recoverable. |

Both Gemini reads were recovered from the conversation history on 9 September
2026 and deposited verbatim. The prompt for both is reproduced in
`gemini_cold_read_2.md`.

## Configured but never returned a review

GPT-4o, GLM-5, Mistral-7B, Llama-3.1-8B (free tier) and Gemini via the Google API
(`gemini-1.5-pro`, `gemini-2.0-flash`, `gemini-1.5-flash`) appear in early run
configurations. Each failed (missing module, authentication, credits, rate
limits or unavailable endpoint) and contributed nothing to the findings.

## Grades

The script's parsed grade for Qwen3-235B is 0 in every run. That is a parsing
error: the RECOMMENDATION line in the response text reads 3 (runs 113433,
114902, 120617, 121155) and 2 (run 124625). The manuscripts report the text
values.
