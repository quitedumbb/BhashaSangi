import os
import requests
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("BHASHINI_INFERENCE_KEY")

url = "https://dhruva-api.bhashini.gov.in/services/inference/pipeline"

headers = {
    "Content-Type": "application/json",
    "Accept": "*/*",
    "Authorization": API_KEY
}

payload = {
    "pipelineTasks": [
        {
            "taskType": "translation",
            "config": {
                "language": {
                    "sourceLanguage": "hi",
                    "targetLanguage": "sat"
                },
                "serviceId": "ai4bharat/indictrans-v2-all-gpu--t4"
            }
        }
    ],
    "inputData": {
        "input": [
            {
                "source": "पौधों को पानी चाहिए।"
            }
        ]
    }
}

response = requests.post(
    url,
    headers=headers,
    json=payload,
    timeout=60
)

print("Status Code:", response.status_code)
if response.status_code == 200:
    data = response.json()
    translated = data["pipelineResponse"][0]["output"][0]["target"]
    print("[SUCCESS] Bhashini Connected!")
    print("Translated text character count:", len(translated))
else:
    print("[ERROR] Response:", response.text)
