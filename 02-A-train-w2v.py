"""
Script to train w2v model and export embeddings for spike gene sequences

"""
import glob
import pandas as pd
from gensim.models import Word2Vec

sequences_dir = "data/fasta_preprocessing/CSVs/countrywise"
model_outpath = "models/word2vec-spike-all-countries-36-VS.model"
output_filename = "data/w2v_output/word2vec-spike-all-countries-36-VS.csv"


def get_kmers(sequence, n_for_nmers=3):
    n_mers = []
    seq_length = len(sequence)
    for i in range(0, seq_length, n_for_nmers):
        n_mers.append(sequence[i: i+n_for_nmers])
    return n_mers


def word2vec_model(tokens, vector_size, window_size):
    model = Word2Vec(tokens, size = vector_size, window = window_size, min_count = 1, sg = 1)
    return model


def create_vec(df, size, col, model):
    vector = []
    for _, row in df.iterrows():
        vec = [0 for i in range(size)]
        seq = row[col]
        for trip in seq:
            wv = model.wv[trip]
            for i in range(size):
                vec[i] += wv[i]
        vec = [i/len(seq) for i in vec]
        vector.append(vec)
    return vector


comb_data = pd.DataFrame()
for file in glob.glob(f'{sequences_dir}/*.csv'):
    comb_data = pd.concat([comb_data, file], axis=0, ignore_index=True)

comb_data['3-mers'] = comb_data['Sequence'].apply(get_kmers)

tokens3 = []
max3 = 0
for seq in comb_data['3-mers']:
    tokens3.append(seq)
    max3 = max(max3, len(seq))

model = word2vec_model(tokens3, 36, 20)
vector = create_vec(comb_data, 36, '3-mers', model)
data1 = pd.concat([comb_data['Accession_ID'], comb_data['Collection_Date'], comb_data['Country'], pd.DataFrame(vector)], axis=1)
data1.to_csv(output_filename, index = False)
model.save(model_outpath)