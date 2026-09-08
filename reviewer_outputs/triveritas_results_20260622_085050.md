# Triveritas Review Report
**Run:** 20260622_085050  
**Paper:** Resurrecting abandoned systematic reviews (Gale, Glue, Guaiana)

## Grade Summary

| Model | Axis | Open-weight | Grade |
|---|---|---|---|
| DeepSeek-R1 (OW) | L | ✓ | ERR |
| Qwen3-235B (OW/OR) | M | ✓ | ERR |
| GLM-5 (OW/OR) | E | ✓ | ERR |
| Gemini 2.0 Flash | N | — | ERR |

**Mean (all):** None  
**Mean (open-weight):** None  
**Mean (proprietary):** None  
**Spread:** None  

## Individual Reviews

---
### [L] DeepSeek-R1 (OW)
**Model:** `deepseek-reasoner` | **Grade:** None | **Open-weight:** Yes | **Time:** 2.8s

*ERROR: Connection error.*

---
### [M] Qwen3-235B (OW/OR)
**Model:** `qwen/qwen3-235b-a22b` | **Grade:** None | **Open-weight:** Yes | **Time:** 0.2s

*ERROR: Error code: 401 - {'error': {'message': 'Missing Authentication header', 'code': 401}}*

---
### [E] GLM-5 (OW/OR)
**Model:** `z-ai/glm-5` | **Grade:** None | **Open-weight:** Yes | **Time:** 0.2s

*ERROR: Error code: 401 - {'error': {'message': 'Missing Authentication header', 'code': 401}}*

---
### [N] Gemini 2.0 Flash
**Model:** `gemini-2.0-flash` | **Grade:** None | **Open-weight:** No | **Time:** 0.8s

*ERROR: 429 Client Error: Too Many Requests for url: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=[REDACTED]*
