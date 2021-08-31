"""
Script to get top Codons for each latent dimension learned by the wor2vec model.

"""
import os
import pandas as pd
from gensim.models import Word2Vec

model_path = "models/word2vec-spike-all-countries-36-VS.model"
output_path = "data/top-codons/"


def get_codon_embeddings(model):
    word_vecs = {}
    for k in model.wv.vocab.keys():
        word_vecs[k] = model.wv[k]
    word_vecs = pd.DataFrame.from_dict(word_vecs, orient = 'index')
    return word_vecs


def get_top_codons_for_dims(word_vecs):
    all_vals = pd.DataFrame()
    word_vecs = word_vecs.applymap(lambda x: abs(x)) # Absolute values

    for dim in range(36):
        # kmer_dict = word_vecs[dim].sort_values(ascending=False)[:10].to_dict()  # Dict for Top 10 absolute values for dim
        kmer_dict = word_vecs[dim].sort_values(ascending=False).to_dict()
        top_df = pd.DataFrame.from_dict(kmer_dict, orient='index').reset_index()
        top_df.columns = [f'Dim{dim+1}_kmers', f'Dim{dim+1}_weights']
        top_df[f'Dim{dim+1}_weights'] = top_df[f'Dim{dim+1}_weights'].apply(lambda x: round(x,2))
        all_vals = pd.concat([all_vals, top_df], axis=1)
    return all_vals


# Main Code
model = Word2Vec.load(model_path)
word_vecs = get_codon_embeddings(model) # Embeddings for each Codon (3mer)
all_vals = get_top_codons_for_dims(word_vecs) # Top Kmers for each Dimension

all_vals.to_csv(os.path.join(output_path, 'kmers_full_ranks.csv'), index=False) # Export results