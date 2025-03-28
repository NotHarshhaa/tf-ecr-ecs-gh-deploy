# Use a lightweight Python image for better performance
FROM python:3.8-slim as base

# Set environment variables for Python optimization
ENV PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PIP_NO_CACHE_DIR=on

# Set the working directory inside the container
WORKDIR /app

# Expose the application port
EXPOSE 80

# Copy only the requirements file to leverage Docker caching
COPY requirements.txt .

# Install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy the rest of the application code
COPY . .

# Use Gunicorn for better performance in production
CMD ["gunicorn", "--bind", "0.0.0.0:80", "app:main"]
