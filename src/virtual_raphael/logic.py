import os
from flask import Flask, render_template, request, jsonify
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from params import Params
from modules import extract_sections_and_sentences, process_pdfs_in_folder
import nltk
from modules import clean_text, clean_text_files_in_folder

""" temp file for the logic """

params = Params()

### modules ###

def load_model_test():
    """ load up all the BERT models (N=53) """

    # Iterate through models
    model_list = {model_name:AutoModelForSequenceClassification.from_pretrained(os.path.join(params.models_folder, model_name)) \
                    for model_name in os.listdir(params.models_folder) \
                    if os.path.isdir(os.path.join(params.models_folder, model_name))}
    return model_list



def preprocess_file(file):

    """ Pre process the input report 
    
    args:
        file: the uploaded file object
    steps:
        - from file to text;
        - tokenize;
    """

    process_pdfs_in_folder(
        params.folder_path, 
        params.start_phrases, 
        params.end_phrases, 
        params.keywords, 
        params.preprocessed_folder)

    # Download NLTK stopwords
    nltk.download('stopwords')
    
    #
    clean_text_files_in_folder(
        params.input_folder, params.output_folder)

    # from the uploaded file object to text 
    # with open(file, "r", encoding="utf-8") as f:

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
    return inputs


def save_preprocessed_file():
    pass



def save_pred_results(predictions):
    """ save the prediction to a file """
    
    # Open the file in write mode
    with open(params.output_file_path, "w", encoding="utf-8") as output_file:
        for p in predictions:
            output_file.write(f"Model Name: {p['model_name']}\n")
            output_file.write(f"Predicted Class: {p['predicted_class']}\n")
