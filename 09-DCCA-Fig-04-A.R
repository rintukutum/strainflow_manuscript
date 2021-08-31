#!/usr/bin/env Rscript

"""
Script to calculate and generate DCCA plots between COVID-19 Cases & Sample Entropy for different lead and lag values.
"""
args = commandArgs(trailingOnly=TRUE)

library(tseries)
library(DCCA)
library(dplyr)
library(plyr)
library(reshape2)
library(ggplot2)
library(ggpubr)

country <- args[1]
path_samp_ent_monthly <- paste0('data/entropy/monthly/fast_samp_entropy_monthly_', country, '.csv')
path_cases <- "data/cases/new_cases.csv"
dcca_out_path <- paste0('figures/entropy/monthly_dcca_samp_entropy_', country, '.pdf')


read_clean_monthly_df <- function(path){
  df <- read.csv(path)
  df <- df[complete.cases(df),]
  st_idx <- as.integer(rownames(df[df$Date == "Mar 2020",])[1])
  # end_idx <- as.integer(rownames(df[df$Date == "Jun 2021",])[1])
  df <- df[st_idx:nrow(df),]
  return (df)
}


compute_dcca <- function(ent_df, cases_monthly){
  all_dcca <- matrix(data=NA, ncol = 21, nrow = 36)
  
  for (dim in 1:36){
    loc = dim+1
    j = 1
    for (i in -10:10){
      if (i < 0) {
        s1 <- lead(cases_monthly, -i)
        s1 <- s1[complete.cases(s1),]$cases
        s2 <- lag(ent_df, -i)
        s2 <- s2[complete.cases(s2),]
        s2 <- s2[,loc]
      }
      else if (i == 0) {
        s1 <- cases_monthly$cases
        s2 <- ent_df[,loc]
      }
      else {
        s1 <- lag(cases_monthly, i)
        s1 <- s1[complete.cases(s1),]$cases
        s2 <- lead(ent_df, i)
        s2 <- s2[complete.cases(s2),]
        s2 <- s2[,loc]
      }
      s1 <- s1/1.0
      res <- rhodcca(s1, s2)$rhodcca
      all_dcca[dim, j] <- res  
      j <- j+1
    }
  }
  colnames(all_dcca) <- paste0('Lag', -10:10)
  all_dcca <- data.frame(all_dcca)
  all_dcca$LS <- paste0('LS', 1:36)
  dcca_m <- melt(all_dcca, id.vars='LS')
  dcca_m$x <- gsub('Lag', '', dcca_m$variable)
  dcca_m$x <- gsub('\\.', '-', dcca_m$x)
  dcca_m$x <- as.numeric(dcca_m$x)
  dcca_m$LS <- factor(dcca_m$LS, levels = unique(dcca_m$LS))
  dcca_m_ind <- dlply(dcca_m, 'LS')
  return (dcca_m_ind)
}



# Main Code
#   1. Read Entropy & New Cases CSVs
samp_ent_monthly <- read_clean_monthly_df(path_samp_ent_monthly)
cases_monthly <- read.csv(path_cases)
cases_monthly <- cases_monthly[cases_monthly$country == country,]

#   2. Calculate DCCA for different leads & lags
dcca_m_ind <- compute_dcca(samp_ent_monthly, cases_monthly)

#   3. Plot results
pdf(dcca_out_path, width=7, height=5)
for (i in 1:36){
  p <- ggplot(dcca_m_ind[[i]], aes(x=x, y=value))+
    geom_bar(stat = 'identity', width = 0.08)+
    facet_wrap(facets = 'LS')+
    ggtitle(paste0(country, ' - DCCA of Sample Entropy & Monthly Cases'))+
    xlab('Lag')+
    ylab('DCCA')+
    ylim(c(-1,1))+
    theme_pubr()
  p <- p + grids(linetype = "dashed")
  print(p)
  
}
dev.off()