"""
Script to combine all embedding CSVs generated from `04-A1-predict-w2v.py`

"""
import glob
import pandas as pd

dataset = pd.DataFrame()
files = glob.glob(f'data/w2v_output/all_CSVs/**/*.csv', recursive=True)

for file in files:
    if '.csv' in file:
        print(file)
        df = pd.read_csv(file)
        dataset = pd.concat([dataset, df], axis=0, ignore_index=True)

dataset.to_csv('data/w2v_output/combined.csv')