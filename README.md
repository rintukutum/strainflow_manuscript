# Strainflow

This repository contains code for the paper [Genomic Surveillance of COVID-19 variants with Language Models and Machine Learning](https://www.biorxiv.org/content/10.1101/2021.05.25.445601v3).

## About The Project
<img src="https://www.biorxiv.org/content/biorxiv/early/2021/08/26/2021.05.25.445601/F1.large.jpg" width=50% height=50%>

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

## Installation

Use the package manager [pip](https://pip.pypa.io/en/stable/) to install the required packages.

```bash
pip install requirements.txt
```

## Authors
Contributor names and contact info
* Sargun Nagpal - sargunnagpal@gmail.com
* Ridam Pal - ridamp@iiitd.ac.in
* Rintu Kutum - rintuk@iiitd.ac.in

## Version History
* 0.1
    * Initial Release

## License
[MIT](https://choosealicense.com/licenses/mit/)

## Acknowledgments
* [GISAID (SARS-CoV-2 genome sequences)](https://www.gisaid.org/)
* [JHU CSSE (COVID-19 cases)](https://github.com/CSSEGISandData/COVID-19)
* [CoV-Seq](https://github.com/boxiangliu/covseq)