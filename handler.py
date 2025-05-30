import os
import asyncio
import aiohttp
import runpod

# Use the MODEL environment variable; fallback to a default if not set
concurrency_modifier = int(os.getenv("CONCURRENCY_MODIFIER", 1))
mode_to_run = os.getenv("MODE_TO_RUN", "serverless")
model_length_default = 25000

print("------- ENVIRONMENT VARIABLES -------")
print("Concurrency: ", concurrency_modifier)
print("Mode running: ", mode_to_run)
print("------- -------------------- -------")

OOBOABOOGA_API_URL = "http://localhost:5000/v1/completions"  # Change endpoint if needed

async def handler(event):
    """
    Handles incoming events and forwards them to the oobabooga web server's OpenAI-compatible endpoint.

    Expected input object (event):
        {
            "input": {
                "model": "<model_file_name>",
                "prompt": "<prompt_text>",
                "max_tokens": <int>,           # Optional
                "temperature": <float>         # Optional
            }
        }
    """
    inputReq = event.get("input", {})
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(OOBOABOOGA_API_URL, json=inputReq) as resp:
                resp.raise_for_status()
                result = await resp.json()
                return result
        except aiohttp.ClientError as e:
            return {"error": f"Failed to contact oobabooga server: {str(e)}"}
        except Exception as e:
            return {"error": f"Unexpected error: {str(e)}"}

# https://docs.runpod.io/serverless/workers/handlers/handler-concurrency
def adjust_concurrency(current_concurrency):
    return concurrency_modifier

if mode_to_run in ["serverless"]:
    runpod.serverless.start({
        "handler": handler,
        "concurrency_modifier": adjust_concurrency,
    })

if mode_to_run == "pod":
    async def main():
        prompt = "Hello World"
        requestObject = {"input": {"prompt": prompt}}
        response = await handler(requestObject)
        print(response)

    asyncio.run(main())