"""
Script to get word embeddings for Spike gene sequences
    1. Read, Combine country CSVs
    2. Filter spike protein
    3. Load model; Get embeddings
    4. Correct 0 indexing
    5. Merge with full data df

"""
from datetime import datetime
import glob
import argparse
import numpy as np
import pandas as pd
from gensim.models import Word2Vec


parser = argparse.ArgumentParser(description='Folder Name')
parser.add_argument('-f', '--fname', type=str, help='Name of input folder (ex: CM-2021-06)')
args = parser.parse_args()


path_gisaid = f'data/w2v-MY-summission/{args.fname}/' # Input sequences CSV
model_path = "models/word2vec-spike-all-countries-36-VS.model"
output_file_basename = f'data/w2v_output/all_CSVs/{args.fname}'
n_for_nmers = 3

location_mapping = {'China': 'China', 'USA': 'USA', 'Japan': 'Japan', 'France': 'France', 'Australia': 'Australia',
                    'India': 'India', 'Germany': 'Germany', 'England': 'UK', 'Italy': 'Italy', 'Iran': 'Iran',
                    'Nigeria': 'Africa', 'Brazil': 'SouthAmerica', 'Canada': 'Canada', 'Mexico': 'Mexico',
                    'Morocco': 'Africa', 'Wales': 'UK', 'Chile': 'SouthAmerica', 'New-Zealand': 'New-Zealand',
                    'Tunisia': 'Africa', 'Senegal': 'Africa', 'Scotland': 'UK', 'Pakistan': 'Pakistan',
                    'Peru': 'SouthAmerica', 'South-Africa': 'Africa', 'Northern-Ireland': 'UK', 'Curacao': 'SouthAmerica',
                    'Bolivia': 'SouthAmerica', 'Egypt': 'Africa', 'Aruba': 'SouthAmerica', 'Uruguay': 'SouthAmerica',
                    'Colombia': 'SouthAmerica', 'Zambia': 'Africa', 'Benin': 'Africa', 'Kenya': 'Africa',
                    'Gambia': 'Africa', 'Mali': 'Africa', 'DRC': 'Africa', 'Madagascar': 'Africa', 'Uganda': 'Africa',
                    'Gabon': 'Africa', 'Argentina': 'SouthAmerica', 'Ecuador': 'SouthAmerica', 'Botswana': 'Africa',
                    'Togo': 'Africa', 'Sierra-Leone': 'Africa', 'Bangladesh': 'Bangladesh', 'Venezuela': 'SouthAmerica',
                    'Equatorial-Guinea': 'Africa', 'Zimbabwe': 'Africa', 'Paraguay': 'SouthAmerica',
                    'Suriname': 'SouthAmerica', 'Iraq': 'Iraq', 'Congo': 'Africa', 'Algeria': 'Africa',
                    'Russia': 'Russia', 'Mozambique': 'Africa', 'Rwanda': 'Africa', 'French-Guiana': 'SouthAmerica',
                    'Mayotte': 'Africa', 'Reunion': 'Africa', 'Cameroon': 'Africa', 'Martinique': 'Africa',
                    'Bonaire': 'SouthAmerica'}


def get_kmers(sequence, n_for_nmers=n_for_nmers):
    n_mers = []
    seq_length = len(sequence)
    for i in range(0, seq_length, n_for_nmers):
        n_mers.append(sequence[i: i+n_for_nmers])
    return n_mers


def create_vec(df, size, col, model):
    mean_vectors = []
    counter = 1
    for _, row in df.iterrows():
        seq_emb = []
        for codon in row[col]:
            emb = model.wv[codon]
            seq_emb.append(emb)
        mean_vectors.append(np.mean(seq_emb, axis=0))
        
        if(counter%10000 == 0):
            print(f'\tProcessed {counter} files')
        counter += 1
    return mean_vectors


def check_sequence_bases(sequence):
    bases_check = (len(set(sequence) - set("ATGC")) == 0)
    if bases_check:
        return True
    else:
        return False


def read_all_csvs():
    dataset = pd.DataFrame()
    countries = glob.glob(f'{path_gisaid}/**/*.csv', recursive=True)

    ignore_list = ['CM-2021-04', 'CM-2021-05', 'CM-2021-06']

    for file in countries:
        for name in ignore_list:
            if name in file:
                continue

        df = pd.read_csv(file)
        idxs = df['Sequence'].apply(lambda x: check_sequence_bases(x))
        df = df.loc[idxs]
        df = df.drop_duplicates(keep='first')
        print('\t', file+": ", df.shape)
        dataset = pd.concat([dataset, df])
    return dataset


def clean_csv(dataset):
    dataset = dataset.reset_index(drop =True)
    dataset = dataset.sort_values(by=['Collection_Date']).reset_index(drop=True)
    dataset = dataset[dataset['Product']== 'surface glycoprotein']
    dataset = dataset[dataset['DividesBy3']==True].reset_index(drop=True)
    dataset['3-mers'] = pd.Series(dataset['Sequence'].apply(get_kmers))
    return dataset


def get_embeddings(dataset):
    model = Word2Vec.load(model_path)
    vectors = create_vec(dataset, 36, '3-mers', model)
    vectors_df = pd.DataFrame(vectors, columns= list(range(1,37)))
    return vectors_df


def main():
    tik = datetime.now()
    print('Reading CSVs')
    dataset = read_all_csvs()
    print('Cleaning CSVs')
    dataset = clean_csv(dataset)
    print('Getting Embeddings')
    vectors_df = get_embeddings(dataset)
    combined_data = pd.concat([dataset, vectors_df], axis=1)
    combined_data = combined_data.drop('Sequence', axis=1)
    
    print('Exporting')
    combined_data = combined_data.reset_index(drop=True)
    parts = len(combined_data)//10000
    if((parts == 0) or (parts==1)):
        combined_data.to_csv(f'{output_file_basename}_1.csv', index=False)
    else:
        for i in range(1, parts+1):
            st_idx = 10000 * (i-1)
            if i != parts:
                end_idx = 10000 * i
                d = combined_data.loc[st_idx:end_idx]
            else:
                d = combined_data.loc[st_idx:]

            d.to_csv(f'{output_file_basename}_{i}.csv', index=False)

    tok = datetime.now()
    print(f'\nTook {(tok-tik).seconds} seconds')

if __name__ == '__main__':
    main()