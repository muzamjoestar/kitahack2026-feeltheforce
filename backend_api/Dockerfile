# Use a lightweight Python image
FROM python:3.10-slim

# Set the working directory
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your app code
COPY . .

# Run the app on port 8080 (Google Cloud expects this port)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]