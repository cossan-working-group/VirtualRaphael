# -*- coding: utf-8 -*-

import os
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
import nltk
import os
from virtual_raphael.modules import process_pdfs_in_folder, clean_text_files_in_folder
from virtual_raphael.params import Params
from virtual_raphael.console import console
import time



def main():

    params = Params()

    ### Pre process the new report ###
    process_pdfs_in_folder(
        params.folder_path, 
        params.start_phrases, 
        params.end_phrases, 
        params.keywords, 
        params.preprocessed_folder)

    # Download NLTK stopwords
    nltk.download('stopwords')
    clean_text_files_in_folder(params.input_folder, params.output_folder)

    ### Begin classification ###


    ### prepare the txt file ###
    text_file_path = None
    for filename in os.listdir(params.text_folder):
        if filename.endswith(".txt"):
            text_file_path = os.path.join(params.text_folder, filename)
            break
    with open(text_file_path, "r", encoding="utf-8") as file:
        text = file.read()

    # Tokenize
    tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)

    # Initialize a list to store predictions
    predictions = []

    start_time=time.time()

    # Iterate through models
    for model_name in os.listdir(params.models_folder):
        # Check if the item in the folder is a directory
        if os.path.isdir(os.path.join(params.models_folder, model_name)):
            # Load the fine-tuned BERT model
            model = AutoModelForSequenceClassification.from_pretrained(os.path.join(params.models_folder, model_name))

            # Make predictions using the tokenized input
            with torch.no_grad():
                outputs = model(**inputs)

            probabilities = torch.softmax(outputs.logits, dim=1)

            predicted_class = torch.argmax(probabilities, dim=1).item()

            # Store
            predictions.append({
                "model_name": model_name,
                "predicted_class": predicted_class,
                "class_probabilities": probabilities.tolist()[0]
            })

    # # Define the output file path
    output_file_path = params.output_file_path

    # Open the file in write mode
    with open(output_file_path, "w", encoding="utf-8") as output_file:
        for prediction in predictions:
            output_file.write(f"Model Name: {prediction['model_name']}\n")
            output_file.write(f"Predicted Class: {prediction['predicted_class']}\n")

    laspsed_time =  time.time() - start_time
    console.log(f"Predictions saved to [bold cyan]{output_file_path}[/bold cyan] which took {laspsed_time:.2f} s") #194 seconds
    

if __name__ == "__main__":
    main()