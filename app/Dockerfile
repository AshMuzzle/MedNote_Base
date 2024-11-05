FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && \
    pip install --no-cache-dir flask werkzeug langchain_community langchain_ollama

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]