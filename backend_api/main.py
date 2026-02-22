from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, status
import google.generativeai as genai
from scanner import analyze_card
from schemas import MatricCardDetails, MatricCardResponse, ServiceDescriptionRequest, ServiceDescriptionResponse
import os
import traceback
from dotenv import load_dotenv
from pathlib import Path

env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

"""Initialize FastAPI app."""
app = FastAPI()

"""Dependency to get configured Gemini API model."""
def get_gemini_api():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        print("❌ ERROR: GEMINI_API_KEY is missing from environment variables!")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="GEMINI_API_KEY not configured in .env file",
        )
    genai.configure(api_key=api_key)
    model=genai.GenerativeModel("gemini-3-flash-preview")
    return model

"""Root endpoint to verify API is running."""
@app.get("/")
def read_root():
    return {"message": "Welcome to the Backend API!"}

"""To verify matric card, send a POST request to /verify-matric-card with form-data containing the image file with key 'file'."""
@app.post("/verify-matric-card")
async def verify_matric_card(file: UploadFile = File(...),
                             model = Depends(get_gemini_api)):
    try:
        #
        image_data = await file.read()
        raw_extracted = analyze_card(image_data, model)
        if "error" in raw_extracted:
            print(f"🚨 DEBUG ERROR: {raw_extracted['error']}") 
            
            # Send the real error to the frontend to see it in Swagger
            return MatricCardResponse(valid=False, message=f"Error: {raw_extracted['error']}")
        
        if raw_extracted.get("valid") is True:
            details = MatricCardDetails(
                matric_number=raw_extracted.get("matric_number", "Unknown"),
                name=raw_extracted.get("name", "Unknown"),
                kulliyyah=raw_extracted.get("kulliyyah", "Unknown"),
            )
            return MatricCardResponse(valid=True, details=details, message="Valid matric card.")
        else:
            return MatricCardResponse(valid=False, message="Invalid matric card.")
    except Exception as e:
        print("🔥🔥🔥 CRITICAL SERVER ERROR:")
        print(traceback.format_exc())
        return MatricCardResponse(valid=False, message=f"Internal Server Error: {str(e)}")

@app.post("/generate-description", response_model=ServiceDescriptionResponse)
async def generate_description(request: ServiceDescriptionRequest, model = Depends(get_gemini_api)):
    try:
        # Build the prompt for Gemini
        prompt = f"""
        You are a smart AI copywriter for a university marketplace app.
        
        Service Title: {request.title}
        Key Details: {request.rough_idea}
        
        Instructions:
        1. **Language Detection**: 
           - If the user's input is primarily English, generate the description in **English**.
           - If the user's input is primarily Malay or Manglish, generate in **Manglish (Bahasa Rojak)**.
           
        2. **Tone Adaptation**:
           - If the service seems professional (e.g., Tutoring, Proofreading, Design), use a **Semi-Formal/Professional** tone.
           - If the service is casual (e.g., Runner, Food, Barber), use a **Casual, Fun, and Viral** tone.
           
        3. **Structure**:
           - Hook (Problem/Question)
           - Solution & Details (Price, Features)
           - Call to Action (Contact/Location)
           
        4. **Formatting**:
           - Use relevant emojis.
           - Keep it under 100 words.
        """
        
        # Call Gemini
        response = model.generate_content(prompt)
        
        return {
            "success": True,
            "description": response.text.strip()
        }
    except Exception as e:
        # If Gemini fails, return the error gracefully
        raise HTTPException(status_code=500, detail=str(e))