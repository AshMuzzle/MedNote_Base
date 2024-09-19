from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate

template = """
Answer the question below.

Here is the conversation history: {context}

Question: {question}

Answer:
"""

model = OllamaLLM(model="llama3.1")
prompt = ChatPromptTemplate.from_template(template)
chain = prompt | model

def handle_conversation():
    context = ""
    print("Welcome to MedNote! Type 'exit' to quit")

    while True:
        user_input = input("User: ")
        if user_input.lower() == "exit":
          break
        result = chain.invoke({"context": context, "question": user_input})
        print("Bot: ", result)
        context += f"\nUser: {user_input}\nAI: {result}"

#result = chain.invoke({"context": "", "question": "hey how are you"})
#result = model.invoke(input="Sing me a song")
#print(result)


if __name__ == "__main__":
   handle_conversation()
