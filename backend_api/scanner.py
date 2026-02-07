import google.generativeai as genai
import os
import json
import re
from dotenv import load_dotenv

"""Load environment variables from .env file."""
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

"""Cleans and extracts JSON object from text."""
def clean_json_text(text: str):
    # Find the first and last curly braces to extract JSON
    clean = re.sub(r"```json|```", "", text).strip()
    return clean
       
"""Function to analyze matric card image and extract details using Gemini API."""
def analyze_card(image_bytes, model)-> dict:
    genai.configure(api_key=api_key)
    model=genai.GenerativeModel("gemini-3-flash-preview")
    
    prompt = """     
    Analyze this image. Check if the card has:
    - International Islamic University Malaysia logo
    - KEMENTERIAN PENDIDIKAN TINGGI text and logo
    - RHB logo
    - "MySISWA" text
    - "ISLAMIC MyDebit" text
    - a chip
    - "VISA Debit" text
    - a background
    printed on it.
    
    Also, check for the matric number format which is usually five or six digits long (e.g., 2519999).
    If yes, extract and return the following details in JSON format ONLY:
    {
    "valid": true,
    "name": "Student Name",
    "matric_number": "Matric Number",
    "kulliyyah": "Kulliyyah Name (shortform)",
    }
    
    If it is not a valid matric card OR there is information missing OR not even a card, return:
    {
    "valid": false
    }
    """
    try:
        response = model.generate_content([prompt,
                                       {'mime_type': 'image/png', 'data': image_bytes}])
        # Extract and clean JSON from the response
        raw_text = response.text
        json_text = clean_json_text(raw_text)
        final = json.loads(json_text)
        return final
    except Exception as e:
        return {"valid": False, "error": str(e)}