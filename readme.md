# MedNote

MedNote is a Flask-based application that uses Ollama’s LLM models for analyzing medical notes. The application is containerized using Docker and optimized for GPU utilization.

## **Project Overview**

MedNote leverages the power of LLMs to assist with the transcription and analysis of medical notes. The application uses Ollama’s large language models to generate responses, extract keywords, and summarize information.

## **Features**

- Live transcription and analysis of medical notes.
- Keyword extraction and summarization using advanced LLM models.
- GPU acceleration for optimized processing.

## **Prerequisites**

- **Docker Desktop**: [Download Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Git**: [Download Git](https://git-scm.com/downloads) (or GitHub Desktop if you prefer)
- **GPU Support** (optional but recommended for performance):
  - Latest GPU drivers
  - CUDA Toolkit ([Install CUDA](https://developer.nvidia.com/cuda-downloads))

## **Installation Guide**

### **1. Clone the Repository**

```bash
git clone -b docker https://github.com/AshMuzzle/MedNote_Base.git
cd MedNote_Base
```

### **2. Move Docker Configuration**

For optimal configuration, move Docker’s `daemon.json` file to the project root:

```powershell
Move-Item -Path .\daemon.json -Destination $env:USERPROFILE\.docker\daemon.json -Force
```

### **3. Start the Application with Docker Compose**

Run the following command from the project root to build and start the Docker containers:

```powershell
docker-compose up --build
```

This command will:
- Build and configure the Flask and Ollama services.
- Pull the necessary language models if they aren’t cached.
- Start the Flask application on port 5000.

### **4. GPU Utilization Setup (Optional)**

To enable GPU acceleration for faster model processing:

1. **Install the Latest GPU Drivers**: Make sure your NVIDIA drivers are up to date.
2. **Install CUDA Toolkit**: [CUDA Download Page](https://developer.nvidia.com/cuda-downloads)

### **5. Accessing the Application**

Once the containers are up and running, access the application at [http://localhost:5000](http://localhost:5000).

## **Project Structure**

```plaintext
MedNote/
├── app/                    # Flask application root.
│   ├── static/             # Static files (CSS, JS, IMG, HTML, PHP).
│   ├── source/             # Log files and prompt files.
│   ├── uploads/            # Directory for uploaded files.
│   ├── downloads/          # Directory for generated downloads.
│   ├── app.py              # Main application file.
│   ├── Dockerfile          # Dockerfile for Flask service.
├── Dockerfile              # Dockerfile for Ollama service.
├── docker-compose.yml      # Docker Compose configuration file.
├── entrypoint.sh           # Docker entrypoint script for Ollama.
├── readme.md               # Project application documentation.
├── security.md             # Project security documentation.
├── robots.txt              # Project privatization.
└── requirements.txt        # Project dependencies.
```

## **Configuration and Customization**

### **Environment Variables**

To customize application settings, configure the following environment variables in `docker-compose.yml`:

- `OLLAMA_BASE_URL`: URL for the Ollama server.
- `OLLAMA_BASE_MODEL`: The default LLM model to use for processing.

### **Changing Models**

By default, the project uses the `llama3.1:8b-instruct-q6_K` model for transcription and analysis. You can change the model in `docker-compose.yml` or in the application’s `app.py`.

## **Troubleshooting**

TBD.

### **Common Issues**

- **Flask starts before Ollama models are ready**: Ensure that `entrypoint.sh` waits until the models are fully downloaded before starting the Ollama server.
- **GPU Not Utilized**: Verify that your GPU drivers and CUDA Toolkit are installed correctly.

### **Checking Logs**

To view logs (/app/source/logs/) and debug, and/or run:

```bash
docker-compose logs -f
```

This will provide real-time output from both Flask and Ollama services.

## **Contributing**

Contributions are closed at this time! Please fork the repository for custom configurations, or submit an issue if you have any improvements.

## **License**

This project is licensed under the MIT License. See the `LICENSE` file for details.
