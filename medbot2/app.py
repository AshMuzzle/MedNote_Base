from flask import Flask, render_template, request, jsonify, send_file
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate
from logging.handlers import RotatingFileHandler
from werkzeug.utils import secure_filename
from werkzeug.exceptions import HTTPException
import speech_recognition as sr
import os
import csv
import tempfile
import logging

# Set directory paths.
HTML_PATH = os.path.join(os.path.dirname(__file__), 'static', 'html')
PROMPT_PATH = os.path.join(os.path.dirname(__file__), 'source', 'prompts', 'live.txt')
LOG_PATH = os.path.join(os.path.dirname(__file__), 'source', 'logs')
UPLOAD_PATH = os.path.join(os.path.dirname(__file__), 'uploads')

# Initialize and configure Flask.
app = Flask(__name__, template_folder=HTML_PATH)
app.config['UPLOAD_PATH'] = UPLOAD_PATH
app.config['MAX_CONTENT_LENGTH'] = 2 * 1024 * 1024
app.config['ALLOWED_EXTENSIONS'] = {'txt'}

# Define error handling.
@app.errorhandler(400)
def invalid_request(error):
    return render_template('400.html'), 400

@app.errorhandler(401)
def invalid_file(error):
    return render_template('401.html'), 401

@app.errorhandler(413)
def invalid_size(error):
    return render_template('413.html'), 413

@app.errorhandler(500)
def internal_error(error):
    return render_template('500.html'), 500

@app.errorhandler(Exception)
def handling_error(e):
    if isinstance(e, HTTPException):
        return e
    app.logger.error(f"Unhandled Exception: {e}")
    return render_template('500.html'), 500

# Define log handling.
if not os.path.exists(LOG_PATH):
    os.makedirs(LOG_PATH)
file_handler = RotatingFileHandler(os.path.join(LOG_PATH, 'app.log'), maxBytes=10240, backupCount=10)
file_handler.setFormatter(logging.Formatter(
    '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)
app.logger.setLevel(logging.INFO)
app.logger.info('Application Startup')

# Verify upload path.
os.makedirs(UPLOAD_PATH, exist_ok=True)

# Verify download file type.
def verify_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def load_prompt():
    with open(PROMPT_PATH, 'r') as file:
        return file.read()

# Load the prompt file.
prompt = load_prompt()

# Initialize LLM.
model = OllamaLLM(model="llama3.1")
prompt = ChatPromptTemplate.from_template(prompt)
chain = prompt | model

# Upload handler.
@app.route('/', methods=['GET', 'POST'])
def upload_file():
    try:
        if request.method == 'POST':
            if 'file' not in request.files or request.files['file'].filename == '':
                return render_template('400.html'), 400
            uploaded_file = request.files['file']
            filename = secure_filename(uploaded_file.filename)
            if not verify_file(filename):
                return render_template('401.html'), 401

            # Save file.
            filepath = os.path.join(app.config['UPLOAD_PATH'], filename)
            uploaded_file.save(filepath)

            # Read file.
            with open(filepath, 'r') as f:
                transcribed_text = f.read()

            # Process file.
            medical_note, keyword_list = process_transcription(transcribed_text)

            # Render file.
            return render_template('selectionpage.html', keywords=keyword_list, medical_note=medical_note)
        return render_template('index.html')

    except Exception as e:
        app.logger.error(f"Error in upload_file: {e}")
        return render_template('500.html'), 500
    

# Transcription handler.
def process_transcription(transcribed_text):
    try:
        model_output = chain.invoke({"context": transcribed_text})

        # Parse the input for output.
        if 'Extracted Keywords:' in model_output:
            note_part, keywords_part = model_output.split('Extracted Keywords:', 1)
            medical_note = note_part.strip()
            keywords_line = keywords_part.strip().split('\n', 1)[0]
            keyword_list = [k.strip() for k in keywords_line.split(',') if k.strip()]
        else:
            medical_note = model_output.strip()
            keyword_list = []
        return medical_note, keyword_list

    except Exception as e:
        app.logger.error(f"Error parsing model output: {e}")
        return transcribed_text.strip(), []

@app.route('/transcribe', methods=['POST'])
def transcribe():
    user_input = request.form.get('user_input')
    context = request.form.get('context', '')

    if user_input:
        context, response = handle_conversation(user_input, context)
        return jsonify({'context': context, 'response': response})
    return jsonify({'error': 'No input received'})

def handle_conversation(user_input, context):
    result = chain.invoke({"context": context, "question": user_input})
    context += f"\nUser: {user_input}\nMedNote: {result}"
    return context, result

@app.route('/selectionpage')
def selection_page():
    return render_template('selectionpage.html')


# Download handler.
@app.route('/downloads', methods=['POST'])
def download_csv():
    try:
        # Form handler.
        selected_keywords = request.form.getlist('keywords')

        # Create CSV.
        with tempfile.NamedTemporaryFile(mode='w+', newline='', delete=False) as temp_csv:
            writer = csv.writer(temp_csv)
            writer.writerow(['Selected Keywords'])
            for keyword in selected_keywords:
                writer.writerow([keyword])
            temp_csv.flush()
            temp_csv_name = temp_csv.name

        # Send CSV.
        response = send_file(temp_csv_name, as_attachment=True, download_name='template.csv')

        # Cleanup handler.
        @response.call_on_close
        def remove_file():
            try:
                os.remove(temp_csv_name)
            except Exception as e:
                app.logger.error(f"Error deleting temp file: {e}")

        return response

    except Exception as e:
        app.logger.error(f"Error generating CSV: {e}")
        return render_template('500.html'), 500

if __name__ == '__main__':
    app.run(debug=True)