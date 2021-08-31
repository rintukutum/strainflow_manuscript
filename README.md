# Strainflow

This repository contains code for the paper [Genomic Surveillance of COVID-19 variants with Language Models and Machine Learning](https://www.biorxiv.org/content/10.1101/2021.05.25.445601v3).

## About The Project
<img src="https://www.biorxiv.org/content/biorxiv/early/2021/08/26/2021.05.25.445601/F1.large.jpg" width=75% height=75%>

* We developed Strainflow for SARS-CoV-2 genome sequences, where sequences were
treated as documents with words (codons) to learn the codon context of 0.9 million
spike genes using the skip-gram algorithm.
* Time series analysis of the information content (Entropy) of the latent dimensions
learnt by Strainflow shows a leading relationship with the monthly COVID-19 cases
for 7 countries (eg. USA, Japan, India and others).
* Machine Learning modeling of the entropy of the latent dimensions helped us to
develop an epidemiological early warning system for the COVID-19 caseloads.
* The top codons associated with the most relevant latent dimensions (DoCs) were
linked to SARS-CoV-2 variants, and DoCs may be used as a surrogate to track the
country-specific spread of the variants.

## File Details
| File | Description | Stage |
| :---         |     :---      |        :--- |
| 01-A1-train-preprocessing.py | Use CoV-Seq script to identify different regions in genome sequences contained in Fasta files | Train data preprocessing |
| 01-A2-train-preprocessing.py | Generate country-wise CSVs for spike gene sequences and associated metadata | Train data preprocessing |
| 02-A-w2v-train.py | Train word2vec skip-gram model on spike gene sequences | word2vec training |
| 02-B-pip-loss.py | Calculate and plot the cumulative PIP loss to select the dimension size of the word embeddings | word2vec model selection |
| 03-A1-augur2covseq.R | GISAID augur format to CoV-Seq annotation | Prediction preprocessing |
| 03-A2-run-2021-04-augur2fa.sh | April 2021 | Prediction preprocessing |
| 03-A2-run-2021-05-augur2fa.sh | May 2021 | Prediction preprocessing |
| 03-A2-run-2021-06-augur2fa.sh | June 2021 | Prediction preprocessing |
| 03-B-prediction-data-preprocess-fasta2w2v.R | Use CoV-Seq annotation file, metadata and fasta to generate input for w2v model  | Prediction preprocessing |
| 03-C-run-2021-04-fa2w2v.sh | April 2021 | Prediction preprocessing |
| 03-C-run-2021-05-fa2w2v.sh | May 2021 | Prediction preprocessing |
| 03-C-run-2021-06-fa2w2v.sh | June 2021 | Prediction preprocessing |
| 04-A-predict-w2v.py | Apr-Jun 2021 | Embedding generation for test data |
| 04-B-combine-embeddings.py | Combine all predictions into a single CSV | Embedding generation for test data |
| 05-A-LD-train-prediction-sfv1.R | Combine the train and prediction latent dimension (LD) of strainflow (sf) version 1 (v1) | Analysis |
| 05-B-Fig-01BC-tSNE-viz.R | Generate tSNE visualisation train LD from 09-2020 to 03-2021 for all (World), UK, China, USA, India | Analysis |
| 05-C-Fig-01D-entropy.R | Generate tSNE visualisation prediction LD from 04-2021 to 06-2021 for all (World), UK, China, USA, India | Analysis |
| 06-Fig-02-dendrogram.py | Calculate cosine similarities between random sequences for plotting dendrogram (phylogenetic tree) on iTol tool | Analysis |
| 07-entropy-calculation.R | Calculate monthly sample entropy for each spike gene latent dimension for a given country | Feature generation |
| 08-new-cases.py | Calculate monthly new cases for each country using data from the JHU COVID-19 cases repository | Outcome variable data collection |
| 09-DCCA-Fig-04-A.R | Calculate and plot the DCCA coefficient between each entropy dimension and new cases for different lead and lag periods. (Figure 4A) | Analysis |
| 10-A-Boruta-RF.R | Entropy dimensions are modeled to predict COVID-19 new cases in the next to next month. Feature selection with Boruta algorithm is performed and Random Forest Regression model is trained. Model inference is performed and Correlation between the actual and predicted values is calculated. (Figure 4C, Table 1) | Predictive Modeling |
| 10-B-Fig-03-05-06-plots.py | Figures 3, 5, 6	| |
| 11-w2v-weights.py | Top codons for each latent dimension are found using embeddings from the trained word2vec model | Interpretability |

## Python Packages Installation

Use the package manager [pip](https://pip.pypa.io/en/stable/) to install the required Python packages.

```bash
pip install requirements.txt
```

## Authors
Contributor names and contact info
* Sargun Nagpal - sargunnagpal@gmail.com
* Ridam Pal - ridamp@iiitd.ac.in
* Rintu Kutum - rintuk@iiitd.ac.in
* Ashima - ashima19031@iiitd.ac.in
* Ananya Tyagi - ananya19114@iiitd.ac.in

## Version History
* 0.1
    * Initial Release

## License
[MIT](https://choosealicense.com/licenses/mit/)

## Acknowledgments
* [GISAID (SARS-CoV-2 genome sequences)](https://www.gisaid.org/)
* [JHU CSSE (COVID-19 cases)](https://github.com/CSSEGISandData/COVID-19)
* [CoV-Seq](https://github.com/boxiangliu/covseq)