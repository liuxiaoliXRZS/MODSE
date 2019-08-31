# This is the main function: be used to get the prediction mortality, model performance, comparing with clinical scores
#                            features importance ranking, figures and tables

import pandas as pd
import features_importance_saier as fms
import model_scores_compare_saier as msc
import mortality_probability_saier as mps

# input data, parameters and path of saving results
mimic_model = pd.read_csv('./mimic_model.csv')
score = pd.read_csv('./clinical_scores.csv')
m = 20 # plot the first 20 importance features ranking
save_path = './' # figures and tables saving path



if __name__ == "__main__":
    # predicting mortality and get results
    input_data = pd.DataFrame()
    input_data = mimic_model
    mps.mortality_probability_saier(input_data, save_path)





