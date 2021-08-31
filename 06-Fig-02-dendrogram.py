"""
Script to calculate cosine similarities between spike embeddings of random sequences for generating Dendrogram (Phylogenetic Tree).

"""
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity

output_file = "data/dendrogram/word2vec-spike-all-countries-36-VS_updated.csv"
df_meta = pd.read_csv("data/dendrogram/Spike-All-3mers-36-VS-metadata.tsv", sep="\t")
df_vec = pd.read_csv("data/dendrogram/Spike-All-3mers-36-VS-vector.tsv", sep="\t", header=None)

print(df_meta.shape, df_vec.shape)

df = pd.concat([df_meta, df_vec], axis=1)
df = df.sample(frac=1, random_state = 1)
df_random = df.groupby("Country").head(25).reset_index(drop=True)
df = df_random.set_index("ID")
df = df.drop(["Country"], axis=1)
c_dist = cosine_similarity(df)
c_dist = 1-c_dist
df = pd.DataFrame(c_dist, columns=df.index.values, index=df.index).reset_index()
df.to_csv(output_file,index=False)