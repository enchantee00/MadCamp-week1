from flask import Flask, request, jsonify
import os
import json
import base64
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import requests
from dotenv import load_dotenv

app = Flask(__name__)
# .env 파일 활성화
load_dotenv()

# 경로: 서비스 계정 JSON 키 파일을 다운로드한 위치
# SERVICE_ACCOUNT_FILE = os.getenv('SERVICE_ACCOUNT_FILE')

# Google Cloud Vision API 키 설정
credentials = service_account.Credentials.from_service_account_file("proteinsequence-425706-316ddb998d60.json")

# OpenAI API 키 설정 (정확한 키를 입력하세요)
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

def detect_text(image_base64):
    """Google Cloud Vision API를 사용하여 텍스트를 감지"""
    client = build('vision', 'v1', credentials=credentials)

    request_body = {
        "requests": [
            {
                "image": {
                    "content": image_base64
                },
                "features": [
                    {
                        "type": "TEXT_DETECTION"
                    }
                ]
            }
        ]
    }

    try:
        response = client.images().annotate(body=request_body).execute()
        ocr_text = response['responses'][0]['fullTextAnnotation']['text']
        return ocr_text
    except KeyError:
        print("KeyError: 'responses' not found in the response")
        return None
    except HttpError as error:
        print(f"An error occurred: {error}")
        return None

def process_text_with_openai(text):
    """OpenAI API를 사용하여 텍스트를 처리"""
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {OPENAI_API_KEY}"
    }
    
    payload = {
        "model": "gpt-3.5-turbo",
        "messages": [
            {
                "role": "user",
                "content": f"Extract the student ID and korean name from this text: {text}"
            }
        ],
        "max_tokens": 300
    }

    response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)

    if response.status_code == 200:
        response_data = response.json()
        try:
            return response_data['choices'][0]['message']['content']
        except (KeyError, IndexError):
            print("Unexpected response structure:", response_data)
            return None
    else:
        print(f"OpenAI API request failed with status code {response.status_code}: {response.text}")
        return None

@app.route('/process_image', methods=['POST'])
def process_image():
    data = request.get_json()
    image_base64 = data.get('image')

    if not image_base64:
        return jsonify({"error": "No image provided"}), 400

    ocr_text = detect_text(image_base64)
    if ocr_text:
        processed_text = process_text_with_openai(ocr_text)
        return jsonify({"ocr_text": ocr_text, "processed_text": processed_text})
    else:
        return jsonify({"error": "No text detected in the image"}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
