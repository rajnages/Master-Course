FROM python:3.9-slim

WORKDIR /app

# Copy and install requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]