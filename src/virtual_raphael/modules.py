import fitz
import re
import os
from nltk.corpus import stopwords
import string
from .console import console

### preprocessing ###

def extract_sections_and_sentences(pdf_path, start_phrases, end_phrases, keywords):
    # Open the PDF file
    pdf_document = fitz.open(pdf_path)

    # Initialize variables to store extracted data
    sections = []
    sentences = []

    # Iterate through each page of the PDF
    for page_num in range(pdf_document.page_count):
        page = pdf_document.load_page(page_num)
        page_text = page.get_text()
        paragraphs = re.split(r'\n|\r\n', page_text)

        # Initialize variables for section extraction
        current_section = ""
        extracting_section = False

        # Iterate through paragraphs to extract sections
        for paragraph in paragraphs:
            # Check for the start of a section
            for start_phrase in start_phrases:
                if start_phrase.lower() in paragraph.lower():
                    current_section = paragraph
                    extracting_section = True
                    break

            # Check for the end of a section
            for end_phrase in end_phrases:
                if end_phrase.lower() in paragraph.lower():
                    current_section += "\n" + paragraph  # Include the end phrase
                    sections.append(current_section)
                    current_section = ""
                    extracting_section = False
                    break

            # If extracting a section, append to the current section
            if extracting_section:
                current_section += "\n" + paragraph

            # Extract sentences containing keywords
            for sentence in re.split(r'(?<=[.!?])\s', paragraph):
                if any(keyword.lower() in sentence.lower() for keyword in keywords):
                    sentences.append(sentence)

    pdf_document.close()

    # Combine sections and sentences
    combined_text = "\n\n".join(sections + sentences)

    return combined_text


def process_pdfs_in_folder(folder_path, start_phrases, end_phrases, keywords, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    pdf_files = [f for f in os.listdir(folder_path) if f.endswith('.pdf')]

    for pdf_file in pdf_files:
        pdf_path = os.path.join(folder_path, pdf_file)
        output_file = os.path.join(output_folder, pdf_file.replace('.pdf', '.txt'))

        combined_text = extract_sections_and_sentences(pdf_path, start_phrases, end_phrases, keywords)

        # Save the combined text to the output file
        with open(output_file, 'w', encoding='utf-8') as file:
            file.write(combined_text)

        console.log(f"Sections and sentences extracted and saved to [bold cyan]'{output_file}'[/bold cyan]")



def clean_text(text):
    # Convert text to lowercase
    text = text.lower()

    # Remove punctuation
    translator = str.maketrans('', '', string.punctuation)
    text = text.translate(translator)
    words = text.split()

    # Remove stopwords
    stop_words = set(stopwords.words('english'))
    words = [word for word in words if word not in stop_words]

    # Join the words back into a cleaned text
    cleaned_text = ' '.join(words)

    return cleaned_text



def clean_text_files_in_folder(input_folder, output_folder):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    txt_files = [f for f in os.listdir(input_folder) if f.endswith('.txt')]

    for txt_file in txt_files:
        input_file_path = os.path.join(input_folder, txt_file)
        output_file_path = os.path.join(output_folder, txt_file)

        with open(input_file_path, 'r', encoding='utf-8') as file:
            text = file.read()

        cleaned_text = clean_text(text)

        with open(output_file_path, 'w', encoding='utf-8') as file:
            file.write(cleaned_text)

        console.log(f"Text cleaned and saved to [bold cyan]'{output_file_path}'[/bold cyan]")