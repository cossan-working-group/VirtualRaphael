"""Hyperparameters for Karl models."""

from dataclasses import dataclass

'''
notes:
    - The following hyperparameters are fixed by Karl.
    -  If they need to dynamically changed depend on the use cases.
    # TODO I'm (Leslie) not sure if these hyperparameters shall be dynamically changed or not.
'''

@dataclass(frozen=True)  # Instances of this class are immutable.
class Params:

    start_phrases = ["recommendation", "lessons learned", "advice to planning authorities"]
    end_phrases = ["reference", "appendix", "annex", "list of", "conclusion", "bibliography", "works cited",
                "introduction", "board member statements", "executive summary", "abbreviations and acronyms"]
    keywords = ["he", "she", "they", "I", "user", "operator", "manager", "management", "team", "lead", "leader",
                "inspector", "mechanic", "engineer", "driver", "pilot", "crew", "worker", "contractor", "operative"]
    
    ### directory structure ###
    folder_path = 'inference_reports/New Report'
    preprocessed_folder = 'inference_reports/New Report Pre Processed'
    input_folder = 'inference_reports/New Report Pre Processed'
    output_folder = 'inference_reports/New Report Cleaned'

    # Define the folder containing models
    models_folder = "models"

    # Define the path to the extracted text file
    text_folder = "inference_reports/New Report Cleaned"

    # Define the output file path
    output_file_path = "Predictions/Predictions.txt"


    @property
    # template for property
    def sth(self):
        """ template for property"""
        return int(round(self.patch_window_seconds / self.stft_hop_seconds))

