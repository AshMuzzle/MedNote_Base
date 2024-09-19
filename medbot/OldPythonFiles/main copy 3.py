import tkinter as tk
from tkinter import filedialog, messagebox
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate
import speech_recognition as sr
import pyttsx3
import keyboard
import os
import time
import threading

# Initialize the model
template = """
Answer the question below.

Here is the conversation history: {context}

Please summarize the following physician-patient conversation into a medical note using the template provided below. Do not add any information that was not mentioned. Do not make anything up or come up with your own diagnoses, your job is to soley organize the text given into this template. If anything is missing, leave it alone, do not add. For example, if Patient name is missing, then keep [Patient's Full Name]:

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

def handle_conversation(user_input, context):
    result = chain.invoke({"context": context, "question": user_input})
    context += f"\nUser: {user_input}\nAI: {result}"
    return context, result

def listen_and_transcribe(context_var, update_gui_callback):
    recognizer = sr.Recognizer()
    while True:
        if keyboard.is_pressed('space'):
            try:
                with sr.Microphone() as mic:
                    recognizer.adjust_for_ambient_noise(mic, duration=0.2)
                    audio = recognizer.listen(mic)
                    
                    text = recognizer.recognize_google(audio)
                    text = text.lower()

                    # Update the context variable and GUI
                    context_var[0] = text
                    update_gui_callback(text)

            except sr.UnknownValueError:
                continue

        time.sleep(0.5)  # Adjust frequency as needed

def update_gui(text):
    if text_display:
        text_display.delete(1.0, tk.END)
        text_display.insert(tk.END, "Transcribed Text:\n" + text)

def start_transcription():
    global context_var
    context_var = [""]
    threading.Thread(target=listen_and_transcribe, args=(context_var, update_gui), daemon=True).start()
    start_page.pack_forget()
    transcription_page.pack()

def load_transcription():
    file_path = filedialog.askopenfilename(filetypes=[("Text files", "*.txt")])
    if file_path:
        with open(file_path, "r") as file:
            text = file.read().strip()
            if text:
                context, response = handle_conversation(text, [""])
                ui_update(text, response)
                start_page.pack_forget()
                transcription_page.pack()

def next_page():
    transcribed_text = context_var[0]
    if transcribed_text:
        context, response = handle_conversation(transcribed_text, [""])
        ui_update(transcribed_text, response)
    else:
        messagebox.showinfo("Info", "No transcription found. Please wait for transcription.")

def ui_update(context, response):
    if text_display:
        text_display.delete(1.0, tk.END)
        text_display.insert(tk.END, "Conversation History:\n" + context)
        response_display.config(text=f"Model Response:\n{response}")

# GUI setup
root = tk.Tk()
root.title("Mednote")

start_page = tk.Frame(root)
start_page.pack(padx=10, pady=10)

label = tk.Label(start_page, text="Mednote", font=("Arial", 24))
label.pack(pady=10)

create_button = tk.Button(start_page, text="Create New Transcription", command=start_transcription)
create_button.pack(pady=5)

load_button = tk.Button(start_page, text="Load Transcription from File", command=load_transcription)
load_button.pack(pady=5)

transcription_page = tk.Frame(root)

text_display = tk.Text(transcription_page, wrap=tk.WORD, height=15, width=50)
text_display.pack(padx=10, pady=10)

response_display = tk.Label(transcription_page, text="", wraplength=400)
response_display.pack(padx=10, pady=10)

next_button = tk.Button(transcription_page, text="Next", command=next_page)
next_button.pack(pady=5)

context_var = [""]  # To hold transcribed text

root.mainloop()
