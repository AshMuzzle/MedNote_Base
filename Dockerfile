FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir flask \
                                langchain-ollama \
                                langchain-core \
                                werkzeug \
                                SpeechRecognition

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]