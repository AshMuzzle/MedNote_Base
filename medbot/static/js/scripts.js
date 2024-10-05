const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
recognition.continuous = false;
recognition.interimResults = false;
recognition.lang = 'en-US';

let isListening = false;

recognition.onresult = function(event) {
    const transcript = event.results[0][0].transcript.toLowerCase();
    document.getElementById('user-input').value += transcript + ' ';
    console.log('Transcribed: ', transcript);
};

recognition.onend = function() {
    if (isListening) {
        recognition.start();  // Restart recognition if listening mode is enabled
    }
};

document.getElementById('listen-btn').addEventListener('click', function() {
    if (!isListening) {
        isListening = true;
        recognition.start();
        document.getElementById('listen-btn').innerText = 'Stop Listening';
        document.getElementById('listen-btn').classList.add('active');
    } else {
        isListening = false;
        recognition.stop();
        document.getElementById('listen-btn').innerText = 'Start Listening';
        document.getElementById('listen-btn').classList.remove('active');
    }
});

document.getElementById('summarize-btn').addEventListener('click', function() {
    transcribeText();
});

document.getElementById('import-btn').addEventListener('click', function() {
    document.getElementById('file-input').click();
});

document.getElementById('file-input').addEventListener('change', function(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const fileContent = e.target.result;
            document.getElementById('user-input').value += fileContent;
            document.getElementById('conversation-history').innerText = fileContent;
            document.getElementById('toggle-btn').innerText = '[Hide]';
            document.getElementById('conversation-history').style.display = 'block';
        };
        reader.readAsText(file);
    }
});

document.getElementById('toggle-btn').addEventListener('click', function() {
    const history = document.getElementById('conversation-history');
    const toggleBtn = document.getElementById('toggle-btn');
    if (history.style.display === 'none') {
        history.style.display = 'block';
        toggleBtn.textContent = '[Hide]';
    } else {
        history.style.display = 'none';
        toggleBtn.textContent = '[Show]';
    }
});

// Add event listener to the edit button
document.getElementById('edit-btn').addEventListener('click', function() {
    const modelResponse = document.getElementById('model-response');
    const editBtn = document.getElementById('edit-btn');

    if (editBtn.innerText === 'Edit') {
        modelResponse.contentEditable = 'true';
        modelResponse.focus();
        editBtn.innerText = 'Save';
        editBtn.classList.add('save-mode'); // Change button to green
        modelResponse.style.border = '1px solid #ccc';  // Optional: Add a border to indicate edit mode
    } else {
        modelResponse.contentEditable = 'false';
        editBtn.innerText = 'Edit';
        editBtn.classList.remove('save-mode'); // Change button back to yellow
        modelResponse.style.border = 'none';  // Remove the border after saving
    }
});

// Add event listener to the export button
document.getElementById('export-btn').addEventListener('click', function() {
    const responseText = document.getElementById('model-response').innerText;
    if (responseText.trim() === "") {
        alert("There's no content to download.");
        return;
    }

    const blob = new Blob([responseText], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    
    const a = document.createElement('a');
    a.href = url;
    a.download = 'medical_note.txt';
    document.body.appendChild(a);
    a.click();

    // Clean up
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
});

document.getElementById('csv-btn').addEventListener('click', function() {
    const medicalNote = document.getElementById('model-response').innerText;

    if (!medicalNote) {
        alert("No medical note to export");
        return;
    }

    const lines = medicalNote.split('\n');
    const csvContent = [];
    
    // Define CSV header (adjust based on the structure of your note)
    csvContent.push(['Section', 'Content']);

    lines.forEach(line => {
        const splitLine = line.split(': ');

        if (splitLine.length === 2) {
            csvContent.push([splitLine[0], splitLine[1]]);
        } else if (splitLine.length === 1) {
            csvContent.push([splitLine[0], '']);
        }
    });

    let csvString = "data:text/csv;charset=utf-8," + csvContent.map(e => e.join(",")).join("\n");

    const encodedUri = encodeURI(csvString);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "medical_note.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
});

function transcribeText() {
    const userInput = document.getElementById('user-input').value;
    const context = document.getElementById('conversation-history').innerText;

    const buttons = document.querySelectorAll('button');
    buttons.forEach(button => {
        button.disabled = true;
    });

    const summarizeBtn = document.getElementById('summarize-btn');
    summarizeBtn.innerText = 'Summarizing in progress';

    let dotCount = 0;
    const loadingInterval = setInterval(() => {
        dotCount = (dotCount + 1) % 4;
        summarizeBtn.innerText = 'Summarizing in progress' + '.'.repeat(dotCount);
    }, 500);

    fetch('/transcribe', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: `user_input=${encodeURIComponent(userInput)}&context=${encodeURIComponent(context)}`
    })
    .then(response => response.json())
    .then(data => {
        clearInterval(loadingInterval);

        buttons.forEach(button => {
            button.disabled = false;
        });

        summarizeBtn.innerText = 'Summarize';

        if (data.error) {
            alert(data.error);
        } else {
            document.getElementById('conversation-history').innerText = data.context;
            document.getElementById('model-response').innerText = data.response;

            document.getElementById('export-btn').style.display = 'block';
            document.getElementById('edit-btn').style.display = 'block';
            document.getElementById('csv-btn').style.display = 'block';

            checkNextPageButtonVisibility();
        }
    })
    .catch(error => {
        console.error('Error:', error);
        clearInterval(loadingInterval);
        
        buttons.forEach(button => {
            button.disabled = false;
        });

        summarizeBtn.innerText = 'Summarize';
    });
}

function checkNextPageButtonVisibility() {
    const exportBtn = document.getElementById('export-btn');
    const editBtn = document.getElementById('edit-btn');
    const csvBtn = document.getElementById('csv-btn');
    const nextPageBtn = document.getElementById('next-page-btn');

    if (exportBtn.style.display === 'block' && editBtn.style.display === 'block' && csvBtn.style.display === 'block') {
        nextPageBtn.style.display = 'inline-block'; // Show the next page button
    } else {
        nextPageBtn.style.display = 'none'; // Hide the next page button
    }
}

document.getElementById('next-page-btn').addEventListener('click', function() {
    const url = this.getAttribute('data-url');
    window.location.href = url;
});
