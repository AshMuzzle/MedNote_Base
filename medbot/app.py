from flask import Flask, render_template, request, jsonify
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate
import speech_recognition as sr
#import pyttsx3 #Old Transcription Service

app = Flask(__name__)

# Initialize the model
template = """

Here is the conversation history: {context}

Task:

You are provided with the transcript of a physician-patient conversation. Your job is to carefully summarize and organize the information into a structured medical note using the template provided below. The medical note should be a clear and concise reflection of the conversation, accurately capturing all relevant details without introducing any new information.

Instructions:

Summarization and Organization:

Summarize the conversation content into the appropriate sections of the medical note.
Ensure that the information is placed correctly according to the template structure.

No Additional Information:

Do not invent or add any information that is not explicitly mentioned in the transcript. Your task is strictly to organize and summarize the provided details.
If any section of the template corresponds to information that was not mentioned in the transcript (e.g., patient name, chief complaint, specific symptoms), leave the placeholder as it is without filling in the section. For example, if the patient's name is not provided, keep "[Patient's Full Name]" in the note.

Adherence to Template:

Follow the template format precisely. If the conversation lacks details for certain sections (e.g., assessment, follow-up), do not attempt to fill in these gaps; simply leave the corresponding placeholders in the template. Furthermore, at the start and end of the output, do not state anything such as "here is the completed note".

Output Requirements:

The final output should be the completed medical note with the information organized into the provided sections. Do not include any additional text, such as headers, explanations, or introductory remarks before the note. If there is no conversation transcribed, simply state, "No conversation". The output should strictly be the note itself, formatted according to the template. Below is the template I need you to follow:

Patient Information:

Name: [Patient's Full Name]
Date of Birth: [DOB]
Date of Visit: [Date]
Provider: [Provider's Name]
Chief Complaint:

[Summarize the patient’s primary concern or reason for the visit.]

History of Present Illness (HPI):

Onset: [When did the symptoms start?]
Duration: [How long have the symptoms been present?]
Location: [Where are the symptoms located?]
Severity: [Describe the severity of the symptoms.]
Characteristics: [Describe the nature or type of symptoms.]
Aggravating Factors: [What factors worsen the symptoms?]
Relieving Factors: [What factors relieve the symptoms?]
Physical Examination:

Vital Signs: [Record any vital signs mentioned in the conversation.]
General Appearance: [Describe the patient's overall appearance if relevant.]
Relevant Findings: [Summarize key physical exam findings.]
Assessment and Plan:

Diagnosis: [Provide the primary diagnosis or differential diagnoses.]
Plan: [Outline the treatment plan, including any further tests, referrals, or interventions.]
Patient Education: [Summarize any patient education or advice given.]
Follow-Up:

Instructions: [Provide instructions for follow-up or next steps.]
Signature:

Provider’s Name: [Provider's Name]
Date: [Date] {question}

Answer:
"""
model = OllamaLLM(model="llama3.1")
prompt = ChatPromptTemplate.from_template(template)
chain = prompt | model

@app.route('/')
def index():
    return render_template('index.html')

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

if __name__ == '__main__':
    app.run(debug=True)
