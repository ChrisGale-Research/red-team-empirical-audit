# Triveritas Review Report
**Run:** 20260622_083824
**Paper:** Resurrecting abandoned systematic reviews (Gale, Glue, Guaiana)

## Grade Summary

| Model | Axis | OW | Grade |
|---|---|---|---|
| Grok (xAI) | L | — | ERR |
| DeepSeek-R1 (OW) | L | ✓ | ERR |
| GPT-4o (OpenAI) | M | — | ERR |
| Qwen3-235B (OW via OpenRouter) | M | ✓ | ERR |
| Gemini 1.5 Pro (Google) | E | — | ERR |
| GLM-5 (OW via OpenRouter) | E | ✓ | ERR |

**Mean (all):** None  
**Mean (open-weight):** None  
**Mean (proprietary):** None  
**Grade spread (max-min):** None  

## Individual Reviews

---
### [L] Grok (xAI)
**Model:** `grok-3` | **Grade:** None | **Open-weight:** No | **Time:** 1.0s

*ERROR: Error code: 400 - {'code': 'invalid-argument', 'error': 'Incorrect API key provided. You can obtain an API key from https://console.x.ai.'}*

---
### [L] DeepSeek-R1 (OW)
**Model:** `deepseek-reasoner` | **Grade:** None | **Open-weight:** Yes | **Time:** 0.8s

*ERROR: Error code: 401 - {'error': {'message': 'Authentication Fails, Your api key: ... is invalid', 'type': 'authentication_error', 'param': None, 'code': 'invalid_request_error'}}*

---
### [M] GPT-4o (OpenAI)
**Model:** `gpt-4o` | **Grade:** None | **Open-weight:** No | **Time:** 0.7s

*ERROR: Error code: 401 - {'error': {'message': 'Incorrect API key provided: .... You can find your API key at https://platform.openai.com/account/api-keys.', 'type': 'invalid_request_error', 'param': None, 'code': 'invalid_api_key'}}*

---
### [M] Qwen3-235B (OW via OpenRouter)
**Model:** `qwen/qwen3-235b-a22b` | **Grade:** None | **Open-weight:** Yes | **Time:** 0.2s

*ERROR: Error code: 401 - {'error': {'message': 'Missing Authentication header', 'code': 401}}*

---
### [E] Gemini 1.5 Pro (Google)
**Model:** `gemini-1.5-pro` | **Grade:** None | **Open-weight:** No | **Time:** 0.6s

*ERROR: 400 Client Error: Bad Request for url: https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=[REDACTED]*

---
### [E] GLM-5 (OW via OpenRouter)
**Model:** `z-ai/glm-5` | **Grade:** None | **Open-weight:** Yes | **Time:** 0.2s

*ERROR: Error code: 401 - {'error': {'message': 'Missing Authentication header', 'code': 401}}*
