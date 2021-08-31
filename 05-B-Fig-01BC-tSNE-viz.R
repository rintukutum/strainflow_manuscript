#----------------
# Author: Rintu Kutum
#----------------
rm(list=ls())
#----------------
# Perform Fast tSNE with fftRtsne
#----------------
# conda activate strainflow
load('data/latent-space/strainflow_v1.RData')
source('softs/FIt-SNE/fast_tsne.R')
# conda activate strainflow
input.tsne <- data.frame(strainflow_v1[,paste0('LD',1:36)])
rownames(input.tsne) <- strainflow_v1$gisaid_epi_isl
set.seed(876)
sf.v1.tsne <- fftRtsne(
  as.matrix(input.tsne),
  fast_tsne_path='softs/FIt-SNE/bin/fast_tsne',
  nthreads = 32
)
colnames(sf.v1.tsne) <- c('tSNE.1','tSNE.2')
rownames(sf.v1.tsne) <- rownames(input.tsne)
xx.df <- data.frame(sf.v1.tsne)
xx.df$country <- as.character(strainflow_v1$country)
xx.df$collection_date <- as.character(strainflow_v1$Collection_Date)
xx.df$years <- sapply(
  xx.df$collection_date,
  function(x){strsplit(x,split = '\\-')[[1]][1]}
)
xx.df$months <- sapply(
  xx.df$collection_date,
  function(x){strsplit(x,split = '\\-')[[1]][2]}
)
xx.df$my <- paste0(xx.df$months,'-',xx.df$years)
years <- sapply(names(table(xx.df$my)),function(x){strsplit(x,split='\\-')[[1]][2]})
order.years <- names(table(xx.df$my)[order(years)])
xx.df$model <- strainflow_v1$model
embed.tsne.v1 <- xx.df

save(embed.tsne.v1,file='data/latent-space/embed.tsne.v1.RData')

#----------------
# Figure 01 B & C
#----------------
rm(list=ls())
library(ggplot2)
library(ggpubr)

load('data/latent-space/embed.tsne.v1.RData')
getCountry.tsne <- function(country="UK"){
  embed.tsne.v1$show <- ifelse(
    embed.tsne.v1$country %in% country,
    yes = country,
    no = 'others'
  )
  embed.tsne.v1$show <- factor(
    embed.tsne.v1$show,
    levels = c('others',country) 
  )
  library(dplyr)
  df_sorted <- embed.tsne.v1 %>% arrange(
    months, years, show
  )
  my <- unique(df_sorted$my)
  years <- sapply(my,function(x){strsplit(x,split='\\-')[[1]][2]})
  df_sorted$my <- factor(
    df_sorted$my,
    levels = my[order(years)]
  )
  red2grey <- RColorBrewer::brewer.pal(n = 11,name = 'RdGy')
  if(length(country)==1){
    color_code <- c(others=red2grey[8],'country' = red2grey[2])
    names(color_code)[2] <- country
  }
  if(length(country)==2){
    accent <- RColorBrewer::brewer.pal(n = 8,name = 'Accent')
    color_code <- c(others=red2grey[8],accent[5:6])
    names(color_code)[2:3] <- country
  }
  tsne.w2v <- ggplot(df_sorted,aes(tSNE.1,tSNE.2)) +
    geom_point(aes(col=show),size=1,alpha=0.8) +
    facet_wrap(facets = 'my') +
    xlab('tSNE 1') +
    ylab('tSNE 2') +
    scale_color_manual(labels = names(color_code),
                       values = color_code) +
    theme_pubr() +
    theme(strip.background = element_blank(),
          strip.text = element_text(vjust = 0),
          legend.key = element_blank(),
          axis.text = element_blank())
  return(tsne.w2v)
}
tsne.uk <- getCountry.tsne()

#----------------
# 09-2020 to 06-2021
temp <- unique(embed.tsne.v1$my)[10:19]

world.embed <- embed.tsne.v1[embed.tsne.v1$my %in% temp,]
usa.embed <- world.embed[world.embed$country == "USA",]
uk.embed <- world.embed[world.embed$country == "UK",]
india.embed <- world.embed[world.embed$country == "India",]
china.embed <- world.embed[world.embed$country == "China",]

world.embed$data <- 'World'
usa.embed$data <- "USA"
uk.embed$data <- "UK"
india.embed$data <- "India"
china.embed$data <- "China"
embed.fig <- rbind(
  world.embed,
  usa.embed,
  uk.embed,
  india.embed,
  china.embed
)
embed.fig$data  <- factor(
  embed.fig$data,
  levels = c("World","India","UK","USA","China")
)
idx.tr <- embed.fig$my %in% temp[1:7]
embed.fig.train <- embed.fig[idx.tr,]
embed.fig.train$my <- factor(
  embed.fig.train$my, levels = temp[1:7]
)
embed.fig.test <- embed.fig[!idx.tr,]
embed.fig.test$my <- factor(
  embed.fig.test$my, levels = temp[-c(1:7)]
)
library(RColorBrewer)

color_code <- c(
  brewer.pal(n=9,name = 'Greys')[4],
  brewer.pal(n=8,name = 'Accent')[5:8]
)
names(color_code) <- unique(embed.fig.train$data)
tsne.w2v.fig01b <- ggplot(
  embed.fig.train,
  aes(tSNE.1,tSNE.2)) +
  geom_point(aes(col=data),size=0.65,alpha=0.5) +
  facet_grid(rows=vars(my),cols=vars(data)) +
  xlab('tSNE 1') +
  ylab('tSNE 2') +
  scale_color_manual(labels = names(color_code),
                     values = color_code) +
  theme_pubr() +
  theme(strip.background = element_blank(),
        legend.key = element_blank(),
        strip.text = element_text(colour = '#c51b7dff',size = 12),
        axis.text = element_blank()) +
  rremove('legend')
#----------------
# Figure 01-B
png('figures/Fig01-B.png',
    width = 700,height = 1000,res = 150)
tsne.w2v.fig01b
dev.off()

tsne.w2v.fig01c <- ggplot(
  embed.fig.test,
  aes(tSNE.1,tSNE.2)) +
  geom_point(aes(col=data),size=0.65,alpha=0.5) +
  facet_grid(rows=vars(my),cols=vars(data)) +
  xlab('tSNE 1') +
  ylab('tSNE 2') +
  scale_color_manual(labels = names(color_code),
                     values = color_code) +
  theme_pubr() +
  theme(strip.background = element_blank(),
        strip.text = element_text(colour = '#2ca089ff',size = 12),
        legend.key = element_blank(),
        axis.text = element_blank()) +
  rremove('legend')
#----------------
# Figure 01-C

png('figures/Fig01-C.png',
    width = 750,height = 500,res = 150)
tsne.w2v.fig01c
dev.off()


