"""
Script to generate data for new COVID-19 cases from the John Hopkins COVID-19 repository.
    https://github.com/CSSEGISandData/COVID-19

    New Cases = Diff(Confirmed Cases)
"""
import os
import pandas as pd

path_cases = "data/cases/"


def get_monthwise_new_cases(df, countries):
    df_all = pd.DataFrame()
    for country in countries:
        print(country)
        d = df[df['Country/Region']==country]
        x = d.T.drop(['Province/State', 'Country/Region', 'Lat', 'Long'], axis=0)
        x = pd.DataFrame(x.sum(axis=1))
        x.index = pd.to_datetime(x.index)
        x = x - x.shift(1)
        x = x.dropna()
        x = x.resample('M').sum()
        x = x.rename(columns = {x.columns[0]: 'cases'})
        x['country'] = country
        df_all = pd.concat([df_all, x], axis=0)

    df_all = df_all.loc[(df_all.index >= '2020-03-01') & (df_all.index < '2021-07-01')]
    df_all['country'] = df_all['country'].replace('US', 'USA')
    return df_all


# Main Code
countries = ['Brazil', 'Canada', 'France', 'Germany', 'India', 'Japan', 'United Kingdom', 'US']

df = pd.read_csv('data/COVID-19/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv')
df_all = get_monthwise_new_cases(df, countries)

df_all.to_csv(os.path.join(path_cases, 'new_cases.csv')) # Export results