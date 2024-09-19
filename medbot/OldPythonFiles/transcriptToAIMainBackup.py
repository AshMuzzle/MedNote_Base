from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate
import speech_recognition as sr
import pyttsx3
import keyboard
import os
import time

template = """
Answer the question below.

Here is the conversation history: {context}

Question: {question}

Answer:
"""

model = OllamaLLM(model="llama3.1")
prompt = ChatPromptTemplate.from_template(template)
chain = prompt | model

def handle_conversation(user_input, context):
    result = chain.invoke({"context": context, "question": user_input})
    print("Bot: ", result)
    context += f"\nUser: {user_input}\nAI: {result}"
    return context

def listen_and_transcribe():
    recognizer = sr.Recognizer()
    transcription_file = "transcription.txt"
    context = ""

    print("Press and hold the spacebar to start transcribing. Release to process the transcription.")
    
    while True:
        if keyboard.is_pressed('space'):
            try:
                with sr.Microphone() as mic:
                    recognizer.adjust_for_ambient_noise(mic, duration=0.2)
                    audio = recognizer.listen(mic)
                    
                    text = recognizer.recognize_google(audio)
                    text = text.lower()

                    # Write the transcribed text to a file
                    with open(transcription_file, "w") as file:
                        file.write(text)

                    print("Transcribed: ", text)

                    # Check if the command to exit was detected
                    if "execute order 66" in text:
                        print("Exit command detected. Terminating...")
                        return  # Exit the function and terminate the program

            except sr.UnknownValueError:
                continue

        if not keyboard.is_pressed('space'):
            if os.path.exists(transcription_file):
                with open(transcription_file, "r") as file:
                    user_input = file.read().strip()
                    if user_input:
                        context = handle_conversation(user_input, context)
                        # Clear the file after processing
                        open(transcription_file, "w").close()

        time.sleep(0.5)  # Adjust frequency as needed

if __name__ == "__main__":
    listen_and_transcribe()
