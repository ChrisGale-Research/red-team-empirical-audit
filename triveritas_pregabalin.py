#!/usr/bin/env python3
"""
triveritas_pregabalin.py
========================
Four-model adversarial review.

Setup — create a file called .env in the same directory:
  DEEPSEEK_API_KEY=sk-...
  OPENROUTER_API_KEY=sk-or-v1-...
  GOOGLE_API_KEY=AIza...

Then simply run:
  python3 triveritas_pregabalin.py

Keys are never shown in terminal output.
"""

import os, json, time, datetime, pathlib, re

# ── Load .env file if present (keys never need to appear in terminal) ────────
def load_env(env_path=None):
    p = pathlib.Path(env_path or pathlib.Path(__file__).parent / ".env")
    if not p.exists():
        return
    for line in p.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        os.environ[key.strip()] = val.strip().strip('"').strip("'")

load_env()

PAPER_PATH = pathlib.Path(__file__).parent / "preg_paper_plain.txt"

def load_paper(path):
    if not path.exists():
        raise FileNotFoundError(f"Paper not found: {path}")
    return path.read_text(encoding="utf-8")

REVIEWER_PROMPT = """\
You are a peer reviewer for Research Synthesis Methods (Wiley).
You have received the following manuscript for review.

Please provide your review in exactly this structure:

SUMMARY (2-3 sentences):
<What the paper claims to contribute>

MAJOR CONCERNS:
<List each concern. For statistical issues include specific numbers \
(e.g. tau² reliability at k=3, I² interpretation, unit-of-analysis \
inflation, Knapp-Hartung coverage). Be precise and technical.>

MINOR CONCERNS:
<Presentation, framing, reference gaps, or other secondary issues>

RECOMMENDATION (0-5):
<Single integer only>
  0 = Hard reject (fatally flawed, no revision path)
  1 = Reject (major problems, not salvageable in current form)
  2 = Major revision (substantial problems but publishable concept)
  3 = Minor revision (good paper, specific fixes needed)
  4 = Accept with minor edits
  5 = Accept as is

GRADE RATIONALE (1-2 sentences):
<Why this grade>

---MANUSCRIPT BEGINS---

{paper}

---MANUSCRIPT ENDS---
"""

MODELS = [
    ("L", "DeepSeek-R1 (OW)",     "call_deepseek",   "deepseek-reasoner",            True),
    ("M", "Qwen3-235B (OW/OR)",    "call_openrouter", "qwen/qwen3-235b-a22b",         True),
    ("E", "Llama-3.1-70B (OW/OR)", "call_openrouter", "meta-llama/llama-3.1-70b-instruct", True),
]
# Gemini and Grok run by hand as independent cold reads (round two design).

def call_deepseek(prompt, model):
    from openai import OpenAI
    key = os.environ.get("DEEPSEEK_API_KEY")
    if not key:
        raise EnvironmentError("DEEPSEEK_API_KEY not set — platform.deepseek.com -> API keys")
    client = OpenAI(api_key=key, base_url="https://api.deepseek.com")
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=2000, temperature=0.3,
    )
    return resp.choices[0].message.content

def call_openrouter(prompt, model):
    from openai import OpenAI
    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise EnvironmentError("OPENROUTER_API_KEY not set — openrouter.ai -> Keys")
    client = OpenAI(
        api_key=key,
        base_url="https://openrouter.ai/api/v1",
        default_headers={"HTTP-Referer": "triveritas-review", "X-Title": "Triveritas"}
    )
    resp = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=2000, temperature=0.3,
    )
    return resp.choices[0].message.content

def call_gemini(prompt, model):
    import requests
    key = os.environ.get("GOOGLE_API_KEY")
    if not key:
        raise EnvironmentError("GOOGLE_API_KEY not set — aistudio.google.com -> Get API key")
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/"
           f"{model}:generateContent?key={key}")
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"maxOutputTokens": 2000, "temperature": 0.3}
    }
    r = requests.post(url, json=payload, timeout=120)
    r.raise_for_status()
    data = r.json()
    return data["candidates"][0]["content"]["parts"][0]["text"]

CALLER_MAP = {
    "call_deepseek":   call_deepseek,
    "call_openrouter": call_openrouter,
    "call_gemini":     call_gemini,
}

def parse_grade(text):
    """Extract 0-5 grade. Handles None, markdown headers, varied formatting."""
    if not text:
        return None
    # Strip markdown: headers (##), bold (**text**), italic (*text*)
    cleaned = re.sub(r'\*{1,2}([^*]*)\*{1,2}', r'\1', text)  # bold/italic content
    cleaned = re.sub(r'^#{1,6}\s*', '', cleaned, flags=re.MULTILINE)  # headers
    # Primary: RECOMMENDATION on same line as digit
    for line in cleaned.splitlines():
        if "RECOMMENDATION" in line.upper():
            m = re.search(r'\b([0-5])\b', line)
            if m:
                return int(m.group(1))
    # Secondary: digit on next non-empty line after RECOMMENDATION
    lines = [l for l in cleaned.splitlines() if l.strip()]
    for i, line in enumerate(lines):
        if "RECOMMENDATION" in line.upper() and i + 1 < len(lines):
            m = re.search(r'\b([0-5])\b', lines[i+1])
            if m:
                return int(m.group(1))
    # Tertiary: look for bold/italic wrapped digit e.g. **2** near keyword
    m = re.search(r'RECOMMENDATION[^0-9]{0,60}[\*_]{0,2}([0-5])[\*_]{0,2}',
                  cleaned, re.IGNORECASE | re.DOTALL)
    return int(m.group(1)) if m else None

def run_triveritas():
    paper  = load_paper(PAPER_PATH)
    prompt = REVIEWER_PROMPT.format(paper=paper)
    ts     = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

    results = {
        "run_id":  ts,
        "paper":   "Resurrecting abandoned systematic reviews (Gale, Glue, Guaiana)",
        "reviews": []
    }

    print(f"\n{'='*70}")
    print(f"TRIVERITAS AUTOMATED REVIEW — {ts}")
    print(f"Models: {len(MODELS)}")
    print(f"{'='*70}\n")

    grades = {}
    for axis, label, caller_name, model_id, open_weight in MODELS:
        print(f"[{axis}] {label} ({model_id})...", end=" ", flush=True)
        t0 = time.time()
        try:
            response = CALLER_MAP[caller_name](prompt, model_id)
            elapsed  = round(time.time() - t0, 1)
            grade    = parse_grade(response)
            grades[label] = grade
            status, error = "OK", None
            print(f"grade={grade} ({elapsed}s)")
            if grade is None and response:
                preview = response[:200].replace('\n', ' ')
                print(f"  [grade not parsed — response preview: {preview}]")
        except Exception as e:
            elapsed  = round(time.time() - t0, 1)
            response = None
            grade    = None
            status, error = "ERROR", str(e)
            print(f"ERROR: {e}")

        results["reviews"].append({
            "axis": axis, "label": label, "model": model_id,
            "open_weight": open_weight, "status": status,
            "grade": grade, "elapsed_s": elapsed,
            "response": response, "error": error,
        })
        time.sleep(2)

    valid  = [g for g in grades.values() if g is not None]
    ow     = [r["grade"] for r in results["reviews"] if r["open_weight"] and r["grade"] is not None]
    prop   = [r["grade"] for r in results["reviews"] if not r["open_weight"] and r["grade"] is not None]

    results["summary"] = {
        "grades":           grades,
        "mean_all":         round(sum(valid)/len(valid), 2) if valid else None,
        "mean_open_weight": round(sum(ow)/len(ow), 2)      if ow    else None,
        "mean_proprietary": round(sum(prop)/len(prop), 2)  if prop  else None,
        "spread":           max(valid) - min(valid)         if len(valid) > 1 else None,
    }

    # Save JSON
    jp = pathlib.Path(f"triveritas_results_{ts}.json")
    jp.write_text(json.dumps(results, indent=2, ensure_ascii=False))

    # Save Markdown
    md = [
        f"# Triveritas Review Report",
        f"**Run:** {ts}  ",
        f"**Paper:** {results['paper']}",
        f"",
        f"## Grade Summary",
        f"",
        f"| Model | Axis | Open-weight | Grade |",
        f"|---|---|---|---|",
    ]
    for r in results["reviews"]:
        md.append(f"| {r['label']} | {r['axis']} | {'✓' if r['open_weight'] else '—'} | {r['grade'] if r['grade'] is not None else 'ERR'} |")

    s = results["summary"]
    md += [
        f"",
        f"**Mean (all):** {s['mean_all']}  ",
        f"**Mean (open-weight):** {s['mean_open_weight']}  ",
        f"**Mean (proprietary):** {s['mean_proprietary']}  ",
        f"**Spread:** {s['spread']}  ",
        f"",
        f"## Individual Reviews",
        f"",
    ]
    for r in results["reviews"]:
        md += [
            f"---",
            f"### [{r['axis']}] {r['label']}",
            f"**Model:** `{r['model']}` | **Grade:** {r['grade']} | "
            f"**Open-weight:** {'Yes' if r['open_weight'] else 'No'} | **Time:** {r['elapsed_s']}s",
            f"",
            r["response"] if r["response"] else f"*ERROR: {r['error']}*",
            f"",
        ]

    mp = pathlib.Path(f"triveritas_results_{ts}.md")
    mp.write_text("\n".join(md), encoding="utf-8")

    print(f"\n{'='*70}")
    print("GRADE SUMMARY")
    print(f"{'='*70}")
    for label, grade in grades.items():
        bar = "█" * (grade or 0)
        print(f"  {label:<35} {str(grade) if grade is not None else 'ERR':>3}  {bar}")
    print(f"\n  Mean all:          {s['mean_all']}")
    print(f"  Mean open-weight:  {s['mean_open_weight']}")
    print(f"  Mean proprietary:  {s['mean_proprietary']}")
    print(f"  Spread:            {s['spread']}")
    print(f"\nJSON: {jp}")
    print(f"Report: {mp}")
    print(f"{'='*70}\n")

if __name__ == "__main__":
    run_triveritas()
