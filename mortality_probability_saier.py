# This code is used to predict modse hospital mortality using ensemble method
# Model: Xgboost 
# By xiaoli liu
# 2019.05.07
import pandas as pd
from sklearn.model_selection import train_test_split
import xgboost as xgb
import warnings
warnings.filterwarnings("ignore") # 拦截异常

def mortality_probability_saier(input_data, save_path):
	"""
    input data: dataframe format, the features and target information of patients
    save_path: the mortality result store path
    output: will get the csv of mortality prediction using xgboost
            mortality_predict_probability.csv
    """


	# ----------------------  Part 1 load data and pro-precessing  -------------------------#
	# mods : 所有 age>=65 岁的MODS患者
	# Input data:
	input_data.gender = input_data.gender.map({'M': 0, 'F': 1})
	# data type2  -- fit to tree model: Xgboost   #
	data_type2 = input_data
	X_type2 = data_type2.drop('death_hosp', axis=1)  # type1 features
	y_type2 = data_type2['death_hosp']



	# ----------------------  Part 2 Train model/Test model/Store  -------------------------#
	# #                                    Xgboost                                 #
	# train/validate and test model 
	predicted_XG = []
	probas_XG = []
	X_train_type2, X_test_type2, y_train_type2, y_test_type2 = train_test_split(X_type2, y_type2, test_size=0.2,
																				random_state=0)
	X_train_t_XG, X_test_t_XG, y_train_t_XG, y_test_t_XG = train_test_split(X_train_type2.drop(['icustay_id'], axis = 1), y_train_type2,
																			test_size=0.2,
																			random_state=0)
	clf_XG_bs = xgb.XGBClassifier(n_jobs=-1, objective='binary:logistic', eval_metric='auc', silent=1, tree_method='approx')
	clf_XG_bs.fit(X_train_t_XG, y_train_t_XG, early_stopping_rounds=10, eval_metric="auc", eval_set=[(X_test_t_XG, y_test_t_XG)])
	evals_result = clf_XG_bs.evals_result()  # restore train results
	predicted_XG = clf_XG_bs.predict(X_test_type2.drop(['icustay_id'], axis=1))
	probas_XG = clf_XG_bs.predict_proba(X_test_type2.drop(['icustay_id'], axis=1))
	# #                                 Store data                               #
	probas_XG = probas_XG[:, 1]
	probas_XG = [round(elem, 3) for elem in probas_XG]
	probas_XG = pd.Series(probas_XG)
	icustay_id = []
	icustay_id = X_test_type2['icustay_id'].reset_index(drop=True)
	# Output data:
	output = pd.DataFrame()
	output = pd.concat([icustay_id, probas_XG], axis=1)
	output.columns = ['icustay_id', 'mortality_probability']
	output.to_csv(save_path + 'mortality_predict_probability.csv',index=False)
