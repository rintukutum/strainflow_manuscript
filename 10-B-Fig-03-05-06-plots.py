"""
Script for plotting Figures 3, 5, 6
"""
import numpy as np
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.lines import Line2D
import matplotlib.ticker as mtick
import seaborn as sns
from datetime import timedelta
import plotly.graph_objects as go


countries = ['Brazil', 'Canada', 'England', 'France', 'Germany', 'India', 'Japan', 'Scotland', 'USA', 'Wales']
samp_entropy_df = {}

for country in countries:
    df = pd.read_csv(f'data/entropy/monthly/fast_samp_entropy_monthly_{country}.csv')
    df['Date'] = pd.to_datetime(df['Date'])
    df = df[(df['Date'] >= '03-01-2020') & (df['Date'] <= '06-30-2021')]
    samp_entropy_df[country] = df

colors = {'France':'darkblue', 'Germany':'dodgerblue', 'Northern-Ireland':'yellowgreen',
         'USA':'orange', 'Canada':'red'}


########## Fig 3
fig, ax = plt.subplots(1,2, figsize=(16,4), sharey=True)
fig.subplots_adjust(hspace=0.2, wspace=0.1)

for country in ['France', 'Germany']:
    v = samp_entropy_df[country].iloc[:,1:37].sum(axis=0)
    if country == 'Germany':
        ax[0].plot(v, color = colors[country], label=country, alpha=0.5)
    else:
        ax[0].plot(v, color = colors[country], label=country)
    ax[0].legend(bbox_to_anchor=(1, 1), loc=1, borderaxespad=0, fontsize=12)
    ax[0].set_xticks(list(range(0,36,2)))
    ax[0].set_xticklabels(list(range(1,37,2)), fontsize=12)
    ax[0].set_xlabel('Dimension', fontsize=13, labelpad=10)

for country in ['USA', 'Canada']:
    v = samp_entropy_df[country].iloc[:,1:37].sum(axis=0)
    ax[1].plot(v, color = colors[country], label=country)
    ax[1].legend(bbox_to_anchor=(1, 1), loc=1, borderaxespad=0, fontsize=12)
    ax[1].set_xticks(list(range(0,36,2)))
    ax[1].set_xticklabels(list(range(1,37,2)), fontsize=12)
    ax[1].set_xlabel('Dimension', fontsize=13, labelpad=10)

fig.text(0.09, 0.5, 'Sum of Entropies', va='center', rotation='vertical', fontsize=13)
plt.suptitle("Sum of Sample Entropies for each dimension", fontsize=16)

fig.savefig("figures/Fig2.png", dpi=500, bbox_inches = 'tight')
plt.show()


########## Fig 5

def get_melted_df(df, dim_nums):
    melted_df = pd.DataFrame()
    
    for dim in dim_nums:
        entropy_dim = f'Entropy_{dim}'
        subdf = df[['Date', entropy_dim]]
        subdf = subdf.rename(columns = {entropy_dim: 'Entropy'})
        melted_df = pd.concat([melted_df, subdf], axis=0, ignore_index=True)
    return melted_df

cases_df = pd.read_csv('new_cases.csv')
cases_df = cases_df.rename(columns = {'Unnamed: 0': 'month'})
cases_df['month'] = pd.to_datetime(cases_df['month'])
cases_df = cases_df[(cases_df['month'] >= '03-01-2020') & (cases_df['month'] <= '06-30-2021')]

rf1 = pd.read_csv('predictions/RF_preds.csv')
rf2 = pd.read_csv('predictions/RF_infer_preds.csv')
rf = pd.concat([rf1, rf2], axis=0, ignore_index=True)
rf['Date'] = pd.to_datetime(rf['Date'])
rf['Date'] = rf['Date'] + timedelta(days=64) # 2 months adjustment
rf['Date'] = rf['Date'].apply(lambda x: datetime.strftime(x, "%b-%y"))


fig, ax = plt.subplots(2, 2, figsize=(16,10))

for country in ['USA']:
    cases = cases_df[cases_df['country'] == country]
    cases['month'] = pd.to_datetime(cases['month'])
    cases['month'] = cases['month'].apply(lambda x: datetime.strftime(x, "%b-%y"))
    
    docs = [32, 27, 28, 17, 2, 22, 13, 25, 5, 7, 3, 14, 35, 31, 20, 15, 6, 30, 12, 24, 4, 34, 16, 26]
    melted_entropy_df = get_melted_df(samp_entropy_df[country], docs)
    melted_entropy_df['Date'] = pd.to_datetime(melted_entropy_df['Date'])
    melted_entropy_df['Date'] = melted_entropy_df['Date'].apply(lambda x: datetime.strftime(x, "%b-%y"))
        
    p1 = sns.lineplot(melted_entropy_df['Date'], melted_entropy_df['Entropy'], ci=95, color='grey', 
                      ax=ax[0,0], alpha=0.4)
    p1.set(xlabel=None)
    p1.set_xticklabels(p1.get_xticks(), size = 10)

    ax[0,0].set_ylabel("Entropy", fontsize=14, labelpad=10)
    legend_elements = [Line2D([0], [0], color='grey', label='Entropy Dimensions')] #, lw=4
    ax[0,0].legend(handles=legend_elements, loc='upper left', fontsize=12)
    ax[0,0].set_title('USA', fontsize=14)
    
    
    every_nth = 2
    for n, label in enumerate(ax[0,0].xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
    
    ax2 = ax[0,0].twinx()
    p2 = sns.lineplot(cases['month'], cases['cases'], color='red', ax=ax2, label='Cases', lw=2.2)
    p2.set(xlabel=None)
    ax2.set_ylabel("Cases", fontsize=14, labelpad=24)
    ax2.legend(loc='upper right', fontsize=12)
    

for country in ['Japan']:
    cases = cases_df[cases_df['country'] == country]
    cases['month'] = pd.to_datetime(cases['month'])
    cases['month'] = cases['month'].apply(lambda x: datetime.strftime(x, "%b-%y"))
    
    docs = [32, 27, 28, 17, 2, 22, 13, 25, 5, 7, 3, 14, 35, 31, 20, 15, 6, 30, 12, 24, 4, 34, 16, 26]
    melted_entropy_df = get_melted_df(samp_entropy_df[country], docs)
    melted_entropy_df['Date'] = pd.to_datetime(melted_entropy_df['Date'])
    melted_entropy_df['Date'] = melted_entropy_df['Date'].apply(lambda x: datetime.strftime(x, "%b-%y"))
        
    p1 = sns.lineplot(melted_entropy_df['Date'], melted_entropy_df['Entropy'], ci=95, color='grey', 
                      ax=ax[1,0], alpha=0.4)
    p1.set(xlabel=None)
    p1.set_xticklabels(p1.get_xticks(), size = 10)

    ax[1,0].set_ylabel("Entropy", fontsize=14, labelpad=10)
    legend_elements = [Line2D([0], [0], color='grey', label='Entropy Dimensions')] #, lw=4
    ax[1,0].legend(handles=legend_elements, loc='upper left', fontsize=12)
    ax[1,0].set_title('Japan', fontsize=14)
    
    every_nth = 2
    for n, label in enumerate(ax[1,0].xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
    
    ax2 = ax[1,0].twinx()
    p2 = sns.lineplot(cases['month'], cases['cases'], color='red', ax=ax2, label='Cases', lw=2.2)
    p2.set(xlabel=None)
    ax2.set_ylabel("Cases", fontsize=14, labelpad=17)

    ax2.legend(loc='upper right', fontsize=12)
    ax2.set_yticks([0, 20000, 40000, 60000, 80000, 100000, 120000, 140000])
    formatter = mtick.ScalarFormatter(useMathText=True)
    formatter.set_scientific(True) 
    formatter.set_powerlimits((-1,1)) 
    ax2.yaxis.set_major_formatter(formatter) 


for country in ['USA']:    
    df = rf[rf['Country']==country]
    ax[0,1].plot(df['Date'], df['cases'], label='Actual Cases', color='r', lw=2.2)
    ax[0,1].plot(df['Date'], df['preds'], label='Predicted cases', color='b', alpha=0.8, lw=2.2)
    ax[0,1].legend(fontsize=12, loc='upper left')
    
    every_nth = 2
    for n, label in enumerate(ax[0,1].xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
ax[0,1].set_title('USA', fontsize=14)


for country in ['Japan']:    
    df = rf[rf['Country']==country]
    ax[1,1].plot(df['Date'], df['cases'], label='Actual Cases', color='r', lw=2.2)
    ax[1,1].plot(df['Date'], df['preds'], label='Predicted cases', color='b', alpha=0.8, lw=2.2)
    ax[1,1].legend(fontsize=12, loc='upper left')
    
    every_nth = 2
    for n, label in enumerate(ax[1,1].xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
 
ax[1,1].set_title('Japan', fontsize=14)

plt.subplots_adjust(left=0.1,
                    bottom=0.1, 
                    right=0.9, 
                    top=0.9, 
                    wspace=0.25, 
                    hspace=0.30)   

plt.savefig('figures/Fig5.jpeg', dpi=500)
plt.show()



########## Fig 6

codon_df = pd.read_csv('data/top-codons/kmers_full_ranks.csv')

def formulate_codon_vs_doc_df(codon_df):
    codon_cols = [f'Dim{i}_kmers' for i in range(1,37)]
    all_codons = codon_df[codon_cols].values.tolist()
    all_codons = [i for row in all_codons for i in row]
    unique_codons = list(set(all_codons))
    print(len(unique_codons))
    
    cod_doc_df = pd.DataFrame({'Codons': unique_codons})
    docs = [3,4,12,13,15,16,25,28,30,32]
    
    for doc in docs:
        codon_col = f'Dim{doc}_kmers'
        wts_col = f'Dim{doc}_weights'
        subdf = codon_df[[codon_col, wts_col]]
        subdf = subdf.rename(columns = {codon_col: 'Codons', wts_col: doc})
        cod_doc_df = cod_doc_df.merge(subdf, on='Codons', how='outer')
    
    cod_doc_df = cod_doc_df.fillna(0)
    cod_doc_df = cod_doc_df.set_index('Codons')
    return cod_doc_df

    
fig = plt.figure(figsize=(14, 14))
gs = fig.add_gridspec(3, 2)

axis1 = fig.add_subplot(gs[:, 0])
axis2 = fig.add_subplot(gs[0, 1])
axis3 = fig.add_subplot(gs[1, 1])
axis4 = fig.add_subplot(gs[2, 1])


# Heatmap
cod_doc_df = formulate_codon_vs_doc_df(codon_df)
sns.heatmap(cod_doc_df, cmap="rocket_r", cbar_kws={"shrink": 0.4}, ax=axis1)
axis1.set_title('Codons & DOC Weights', fontsize=14)
axis1.set_xlabel("Dimensions of Concern", fontsize=14, labelpad=10)
axis1.set_ylabel("Codons", fontsize=14, labelpad=10)


# Lineplots
country_ax_map = {'England':axis2, 'India':axis3, 'USA': axis4}

for country in ['England', 'India', 'USA']:
    axes = country_ax_map[country]
    
    cases = cases_df[cases_df['country'] == country]
    cases['month'] = pd.to_datetime(cases['month'])
    cases['month'] = cases['month'].apply(lambda x: datetime.strftime(x, "%b-%y"))
    
    docs = [3, 4, 12, 13, 15, 16, 25, 28, 30, 32]
    melted_entropy_df = get_melted_df(samp_entropy_df[country], docs)
    melted_entropy_df['Date'] = pd.to_datetime(melted_entropy_df['Date'])
    melted_entropy_df['Date'] = melted_entropy_df['Date'].apply(lambda x: datetime.strftime(x, "%b-%y"))
        
    p1 = sns.lineplot(melted_entropy_df['Date'], melted_entropy_df['Entropy'], ci=95, color='grey', 
                      ax=axes, alpha=0.4)
    p1.set(xlabel=None)
    p1.set_xticklabels(p1.get_xticks(), size = 10)

    axes.set_ylabel("Entropy", fontsize=14, labelpad=10)
    legend_elements = [Line2D([0], [0], color='grey', label='Entropy Dimensions')]
    axes.legend(handles=legend_elements, loc='upper left', fontsize=12)
    axes.set_title(country, fontsize=14)
    
    
    every_nth = 2
    for n, label in enumerate(axes.xaxis.get_ticklabels()):
        if n % every_nth != 0:
            label.set_visible(False)
    
    ax2 = axes.twinx()
    p2 = sns.lineplot(cases['month'], cases['cases'], color='red', ax=ax2, label='Cases', lw=2.2)
    p2.set(xlabel=None)
    ax2.set_ylabel("Cases", fontsize=14, labelpad=10)
    ax2.legend(loc='upper right', fontsize=12)
    

plt.subplots_adjust(left=0.1,
                    bottom=0.1, 
                    right=0.9, 
                    top=0.9, 
                    wspace=0.20, 
                    hspace=0.35)   

plt.savefig('figures/Fig6.jpeg', dpi=500)
plt.show()