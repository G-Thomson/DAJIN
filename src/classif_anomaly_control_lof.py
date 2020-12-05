import sys
import numpy as np
import pandas as pd

import pickle

from sklearn.neighbors import LocalOutlierFactor

################################################################################
#! I/O naming
################################################################################

#===========================================================
#? Auguments
#===========================================================

args = sys.argv
file_name = args[1]
threads = int(args[2])

if threads == "":
    import multiprocessing
    threads = multiprocessing.cpu_count() // 2

#===========================================================
#? Input
#===========================================================

df_control_score = pd.read_csv(file_name, header=None)
df_control_score.columns = ["score"]

################################################################################
#! Novelty detection by LOF
################################################################################

#===========================================================
#? Local Outlier Factor
#===========================================================

clf = LocalOutlierFactor(
    novelty=True,
    n_jobs=threads,
)
tmp = df_control_score.score.to_numpy()
clf.fit(tmp.reshape(-1, 1))

################################################################################
#! Save
################################################################################

pickle.dump(clf, open(".DAJIN_temp/classif/tmp_control_lof.sav", "wb"))
