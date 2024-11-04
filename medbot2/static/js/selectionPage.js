        // JavaScript to handle checkbox selection and display corresponding text in the textarea
        const selectedContent = document.getElementById('selected-content');
        
        // Load the medical note from sessionStorage if available
        const medicalNoteText = sessionStorage.getItem('medicalNote') || 'No medical note available';
        const medicalNote = medicalNoteText.trim().split('\n');
        
        // Mapping of checkboxes to the respective sections in the medical note
        const sections = {
            'option1': 'Name:', 
            'option2': 'Date of Birth:', 
            'option3': 'Date of Visit:', 
            'option4': 'Provider:', 
            'option5': 'Chief Complaint:', 
            'option6': 'History of Present Illness (HPI):', 
            'option7': 'Onset:', 
            'option8': 'Duration:', 
            'option9': 'Location:', 
            'option10': 'Severity:', 
            'option11': 'Characteristics:', 
            'option12': 'Aggravating Factors:', 
            'option13': 'Relieving Factors:', 
            'option14': 'Physical Examination:', 
            'option15': 'Vital Signs:', 
            'option16': 'General Appearance:', 
            'option17': 'Relevant Findings:', 
            'option18': 'Assessment and Plan:', 
            'option19': 'Diagnosis:', 
            'option20': 'Plan:', 
            'option21': 'Patient Education:', 
            'option22': 'Follow-Up:', 
            'option23': 'Instructions:', 
            'option24': 'Provider Name:', 
            'option25': 'Date:', 
            'option26': 'ICD-10 Codes:'
        };
        
        // Add event listeners to checkboxes
        document.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
            checkbox.addEventListener('change', updateSelectedContent);
        });
        
        function updateSelectedContent() {
            let content = '';
            let icd10Codes = []; // Array to hold ICD-10 codes
        
            // Loop through each checkbox
            for (const [key, label] of Object.entries(sections)) {
                if (document.getElementById(key).checked) {
                    if (label === 'ICD-10 Codes:') {
                        // Gather all ICD-10 codes
                        medicalNote.forEach(line => {
                            if (line.trim().startsWith('1. ') || line.trim().startsWith('2. ') || 
                                line.trim().startsWith('3. ') || line.trim().startsWith('4. ') || 
                                line.trim().startsWith('5. ')) {
                                icd10Codes.push(line.trim());
                            }
                        });
                        content += `${label}\n${icd10Codes.join('\n')}\n\n`;
                    } else {
                        // Loop through each line of the medical note for other sections
                        for (const line of medicalNote) {
                            if (line.trim().startsWith(label)) {
                                content += `${line.trim()}\n\n`;
                                break;
                            }
                        }
                    }
                }
            }
            selectedContent.value = content; // Update the textarea with the selected content
        }