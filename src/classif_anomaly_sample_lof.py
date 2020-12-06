import sys
import numpy as np
import pandas as pd

import pickle

from sklearn.preprocessing import scale

################################################################################
#! I/O naming
################################################################################

#===========================================================
#? Auguments
#===========================================================

args = sys.argv
file_name = args[1]

#===========================================================
#? Input
#===========================================================

df_score = pd.read_csv(file_name, header=None)
df_score.columns = ["id", "score", "allele"]

df_score["score"] = scale(df_score["score"])

clf = pickle.load(open(".DAJIN_temp/classif/tmp_control_lof.sav", "rb"))

################################################################################
#! Novelty detection by LOF
################################################################################

#===========================================================
#? Local Outlier Factor
#===========================================================
tmp = df_score.score.to_numpy()

outliers = clf.predict(tmp.reshape(-1, 1))
outliers = np.where(outliers == 1, "normal", "abnormal")

df_score["outliers"] = outliers

df_score["allele"].\
    mask(df_score["outliers"] == "abnormal", "abnormal", inplace = True)



################################################################################
#! Save
################################################################################

df_score.to_csv(
    file_name.replace(".csv", "_lof"),
    header=False,
    index=False,
    sep="\t"
)