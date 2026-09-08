# Reviewer outputs

Raw outputs of the multi-model adversarial pass reported in the manuscript
(Section 2.4, Table 3). Every run of the orchestration script
(`../triveritas_pregabalin.py`) is deposited, including failed and partial runs,
because the manuscript reports instability across runs and a reader should be
able to see the whole sequence, not a curated subset. Each run produced a
`.json` (structured) and a `.md` (readable rendering) with the same stem.

API keys that appeared inside error messages have been redacted
(`key=[REDACTED]`); nothing else has been altered.

Timestamps are NZST, 21-22 June 2026. The manuscript under review was the
pre-reframing draft ("Resurrecting abandoned systematic reviews: a reproducible
R pipeline for RevMan 5 files with structured adversarial verification"), i.e.
the version whose central novelty claim the panel invalidated.

## Run log

| Run | Panel configured | Outcome |
|-----|------------------|---------|
| `20260621_192240` | Grok-3, DeepSeek-R1, GPT-4o, Qwen3-235B, Gemini 1.5 Pro, GLM-5 | All failed: Python `openai` module not installed |
| `20260622_083824` | same | All failed: invalid or missing API keys |
| `20260622_085050` | DeepSeek-R1, Qwen3-235B, GLM-5, Gemini 2.0 Flash | All failed: connection, auth, rate limit |
| `20260622_085517` | same | All failed: insufficient credits / rate limit |
| `20260622_113433` | same | DeepSeek-R1 review returned (truncated); Qwen3-235B review returned (text grade 3; parsed 0, see note); GLM-5 and Gemini failed |
| `20260622_114902` | DeepSeek-R1, Qwen3-235B, Mistral-7B, Gemini 2.0 Flash | DeepSeek-R1 truncated after summary; Qwen3-235B review returned (text grade 3; parsed 0); Mistral and Gemini failed |
| `20260622_115834` | DeepSeek-R1, Qwen3-235B, Mistral-7B, Gemini 1.5 Flash | All failed: environment variables not set |
| `20260622_120341` | same | All failed: environment variables not set |
| `20260622_120617` | same | DeepSeek-R1 review returned (truncated); Qwen3-235B review returned (text grade 3; parsed 0); Mistral and Gemini failed |
| `20260622_121155` | DeepSeek-R1, Qwen3-235B, Llama-3.1-8B, Gemini | DeepSeek-R1 review returned (truncated); Qwen3-235B review returned (text grade 3; parsed 0); Llama-8B and Gemini failed |
| `20260622_124625` | DeepSeek-R1, Qwen3-235B, Llama-3.1-70B | **Full panel.** DeepSeek-R1 truncated after summary; Qwen3-235B review returned (text grade 2; parsed 0); Llama-3.1-70B review returned (grade 2) |

## Notes for readers

- **Grade-parsing artefact.** The script recorded Qwen3-235B's grade as 0 in
  every successful run; the RECOMMENDATION line in the response text reads 3
  (runs 113433, 114902, 120617, 121155) and 2 (run 124625). The manuscript
  reports the text values.
- **DeepSeek-R1 truncation.** DeepSeek-R1 responses are cut off before the
  RECOMMENDATION line in every run, most severely in runs 114902 and 124625.
  The substantive concerns attributed to DeepSeek-R1 in Table 3 (unit of
  analysis, I2/tau2 at k = 3, unverified SD, circular validation against the
  superseding NMA, parser generalisability) are visible across runs 113433,
  120617 and 121155.
- **Proprietary models.** Grok, GPT-4o and Gemini were configured in early
  runs but never returned a review through the script. The Gemini and Grok
  cold reads reported in the manuscript were run interactively in the web
  interfaces. Both Gemini reads were recovered from the conversation history
  in September 2026 and are in `cold_reads/` (two `.md` files with the prompt
  and sequencing, plus the raw recovered text as `.docx`). The Grok read was
  not retained and could not be recovered; the concern attributed to Grok in
  Table 3 (that the multi-model claim required a prior-art search) rests on
  the authors' contemporaneous record only. This is a gap in the deposit.
- **Model availability.** Several endpoints failed because the model had been
  withdrawn or renamed between configuration and execution (Mistral-7B free
  tier, Llama-3.1-8B free tier, `gemini-pro`, `gemini-1.5-flash`). This is the
  link-rot problem the manuscript's Discussion refers to.
