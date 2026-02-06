from google import genai
import os
from dotenv import load_dotenv, find_dotenv

load_dotenv(find_dotenv())

client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))
response = client.models.generate_content_stream(
    model="gemini-3-flash-preview",
    contents="Write a poem about the sea." ''' Example of streaming content generation '''
)

for stream in response:
    print(stream.text)