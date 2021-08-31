#!/usr/bin/env Rscript
"""
Script to generate sample entropy CSV for a country, given its embeddings CSV.
  Example: `Rscript entropy-calculation.R USA`
"""
args = commandArgs(trailingOnly=TRUE)

library(TSEntropies)
library(zoo)
library(lubridate)

embeddings_folder <- "data/embeddings/countrywise/"
entropy_output_folder <- "data/entropy/monthly/"


calc_monthly_entropy <- function(entropy_funct){
  subdf <- df[,-c(1,3)]
  subdf <- data.frame(apply(subdf[,-1], 2, as.numeric))
  subdf <- cbind(df$Collection_Date,subdf)
  zoo_df <- read.zoo(subdf)
  monthly_ap_entropy <- aggregate(zoo_df, as.yearmon, entropy_funct)
  colnames(monthly_ap_entropy) <- paste0("Entropy_", c(1:ncol(monthly_ap_entropy)))
  monthly_ap_entropy_df <- fortify.zoo(monthly_ap_entropy, name = "Date")
  return (monthly_ap_entropy_df)
}


# Main script
country <- args[1]

path_emb <- paste0(embeddings_folder, country, '_embeddings.csv')
df <- read.csv(path_emb)
df$Collection_Date = as.Date(df$Collection_Date)

monthly_ap_entropy_df <- calc_monthly_entropy(FastSampEn)
out_path <- paste0(entropy_output_folder, 'fast_samp_entropy_monthly_', country, '.csv')
write.csv(monthly_ap_entropy_df, file=out_path, row.names=FALSE)