import numpy as np
import pandas as pd
import plotly.graph_objects as go
from gensim.models import Word2Vec
from sklearn.linear_model import LinearRegression

models_path = "models/test/"


def create_df(model):
  df = pd.DataFrame()
  for vocab in model.wv.vocab.keys():
      df = pd.concat([df, pd.DataFrame(model.wv[vocab]).T])
  df.index = model.wv.vocab.keys()
  return df


def calculate_loss(df1, df2):
    loss = np.sqrt(((df1.dot(df1.T) - df2.dot(df2.T))**2).sum().sum())
    return loss


dim = [3,6,9,10,12,15,18,20,21,24,27,30,33,36,39,42,45,48,51,54,57,60,63,64]
keys = []
values = []
errors = {}
for ind in range(len(dim)-1):
    model1 = Word2Vec.load(models_path + "word2vec-spike-aus-uk-3mers-"+str(dim[ind])+"-VS.model")
    model2 = Word2Vec.load(models_path + "word2vec-spike-aus-uk-3mers-"+str(dim[ind+1])+"-VS.model")

    df1 = create_df(model1)
    df2 = create_df(model2)
    df2.reindex(df1.index)
    
    pip_loss = calculate_loss(df1, df2)
    errors[str(dim[ind])+"_"+str(dim[ind+1])] = pip_loss
    keys.append(str(dim[ind+1]) +"_"+ str(dim[ind]))
    values.append(pip_loss)

values = values[::-1]
values = np.cumsum(values)
keys = keys[::-1]
key_index = [i for i in range(len(keys))]

k = np.array(key_index).reshape(-1, 1)
v = np.array(values).reshape(-1, 1)

lgr1 = LinearRegression().fit(k[:10], v[:10])
lgr2 = LinearRegression().fit(k[9:13], v[9:13])
lgr3 = LinearRegression().fit(k[12:17], v[12:17])
lgr4 = LinearRegression().fit(k[16:], v[16:])

k1 = []
for i in lgr1.predict(k[:10]):
  k1.append(i[0])

k2 = []
for i in lgr2.predict(k[9:13]):
  k2.append(i[0])

k3 = []
for i in lgr3.predict(k[12:17]):
  k3.append(i[0])

k4 = []
for i in lgr4.predict(k[16:]):
  k4.append(i[0])



# Plot Cumulative PIP Loss
fig = go.Figure()
fig.add_trace(go.Scatter(x=keys[:10], y=k1,line=dict(color="#087FF5")))
fig.add_trace(go.Scatter(x=keys[9:13], y=k2, line=dict(color="#087FF5")))
fig.add_trace(go.Scatter(x=keys[12:17], y=k3, line=dict(color="#087FF5"))) 
fig.add_trace(go.Scatter(x=keys[16:], y=k4, line=dict(color="#087FF5"))) 
fig.update_layout(
    title={
            'text' : "Cumulative PIP Loss for Word2Vec 3-mer Embeddings",
            'x':0.5,
        },
    yaxis_title = 'PIP-Loss',
    template = 'plotly_white',
    width=800,
    height=500,
    showlegend=False,
    )
fig.show()