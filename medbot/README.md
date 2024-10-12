# MedNote Web App

This project is a Flask-based web application that transcribes user voice input or imports text files and summarizes the content into a medical note using LangChain and Ollama LLM. The app is designed to assist healthcare professionals in organizing patient information into structured medical notes.

-----------------
LAUNCHING:
Run app.py and navigate to http://127.0.0.1:5000/
-----------------

## Features

- **Voice Transcription:** Uses Web Speech API to transcribe spoken input.
- **Text Import:** Allows importing a text file containing conversation data.
- **Medical Note Summarization:** Summarizes the transcribed or imported text into a structured medical note.
- **Export Functionality:** Allows exporting the summarized medical note as a text file.

## Installation

### Prerequisites

- Python 3.8 or higher
- pip (Python package installer)

### Step-by-Step Guide

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/mednote-web-app.git
    cd mednote-web-app
    ```

2. **Set up a virtual environment:**

    ```bash
    python3 -m venv venv
    source venv/bin/activate  # On Windows, use `venv\Scripts\Activate.ps1`
    ```

3. **Install the required packages:**

    ```bash
    pip install Flask langchain-ollama langchain-core SpeechRecognition
    ollama run llama3.1
    ctrl+d
    ```

4. **Run the Flask application:**

    ```bash
    python app.py
    ```

5. **Access the application:**

    Open your web browser and navigate to `http://127.0.0.1:5000/`.

## Usage

1. **Transcribe Voice Input:**
   - Click on "Start Listening" to begin voice transcription. The transcribed text will appear in the text area.
   - Click on "Stop Listening" to end the transcription.

2. **Import Text File:**
   - Click on "Import Convo from File" to upload a text file. The content will be added to the text area and displayed in the conversation history.

3. **Summarize Conversation:**
   - After entering or importing the conversation, click "Summarize" to generate a structured medical note.

4. **Export Medical Note:**
   - Once the summary is generated, click "Download Text File" to export the medical note as a `.txt` file.

## Project Structure

```
mednote-web-app/
├── app.py                 # Main Flask application
├── templates/
│   └── index.html         # HTML file for the web interface
├── static/
│   ├── css/
│   │   └── styles.css     # CSS file for styling the web interface
│   └── js/
│       └── scripts.js     # JavaScript file for handling client-side functionality
└── README.md              # Project documentation
```

### File Descriptions

- **app.py:** The core of the Flask application, handling the routes, model initialization, and summarization logic.
- **index.html:** The main HTML file rendered by Flask, providing the user interface.
- **styles.css:** The stylesheet that provides styling to the web interface, ensuring a clean and user-friendly design.
- **scripts.js:** Contains JavaScript code that manages voice transcription, text file import, summarization requests, and exporting the summarized note.
