from fastapi import FastAPI, File, UploadFile, Depends, HTTPException, status
import google.generativeai as genai
from scanner import analyze_card
from schemas import MatricCardDetails, MatricCardResponse
import os

"""Initialize FastAPI app."""
app = FastAPI()

"""Dependency to get configured Gemini API model."""
def get_gemini_api():
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
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