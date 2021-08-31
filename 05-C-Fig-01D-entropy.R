#----------------
# Author: Rintu Kutum
#----------------
rm(list=ls())
# conda activate strainflow
load('data/latent-space/strainflow_v1.RData')

library(plyr)
mod <- dlply(
  .data = strainflow_v1,
  .variables = 'model'
)
tr <- mod$`sfv1:train`
tt <- mod$`sfv1:prediction`


ld.names <- colnames(strainflow_v1)[grep('LD',colnames(strainflow_v1))]

getMonthEntropy <- function(x){
  library('TSEntropies')
  xx <- data.frame(x[,ld.names])
  entropy.month <- apply(xx,2,FastSampEn)
  df_ <- data.frame(LS = ld.names,entropy = entropy.month)
  idx.666 <- df_$entropy == 666
  if(any(idx.666)){
    df_$entropy[idx.666] <- 0 
  }
  return(df_)
}
tr.ym <- dlply(tr,'ym',function(x){
  dlply(x,'country')
})
library(foreach)

tr.month.entropy <- foreach(i=1:length(tr.ym))%do%{
  print(i)
  x.country <- tr.ym[[i]]
  month.entrpy <- foreach(j=1:length(x.country))%do%{
    x.month <- x.country[[j]]
    if(nrow(x.month)>19){
      xx.df <- getMonthEntropy(x.month)
    }else{
      xx.df <- data.frame(LS = ld.names,entropy = NA)
    }
    xx.df
  }
  names(month.entrpy) <- names(x.country)
  entrpy_df <- ldply(
    month.entrpy,
    .id = 'country'
  )
}
names(tr.month.entropy) <- names(tr.ym)
tr.me.df <- ldply(tr.month.entropy,.id = 'ym')
tr.me.df <- na.omit(tr.me.df)
tr.avg <- ddply(tr.me.df,'country',
                function(x){
                  ddply(x,'ym',
                        function(x){data.frame(avg.entropy=mean(x$entropy))}
                  )})

tt.ym <- dlply(tt,'ym',function(x){dlply(x,'country')})
tt.month.entropy <- foreach(i=1:length(tt.ym))%do%{
  print(i)
  x.country <- tt.ym[[i]]
  month.entrpy <- foreach(j=1:length(x.country))%do%{
    x.month <- x.country[[j]]
    if(nrow(x.month)>19){
      xx.df <- getMonthEntropy(x.month)
    }else{
      xx.df <- data.frame(LS = ld.names,entropy = NA)
    }
    xx.df
  }
  names(month.entrpy) <- names(x.country)
  entrpy_df <- ldply(month.entrpy,.id = 'country')
}
names(tt.month.entropy) <- names(tt.ym)
tt.me.df <- ldply(tt.month.entropy,.id = 'ym')
tt.me.df <- na.omit(tt.me.df)
tt.avg <- ddply(tt.me.df,'country',
                function(x){
                  ddply(x,'ym',
                        function(x){data.frame(avg.entropy=mean(x$entropy))}
                  )})

tr.avg$model <- 'Train'
tt.avg$model <- 'Prediction'
idx.tr.fig <- as.character(tr.avg$ym) %in% levels(tr.avg$ym)[4:16]
idx.tt.fig <- as.character(tt.avg$ym) %in% levels(tt.avg$ym)[16:18]
figBC <- rbind(
  tr.avg[idx.tr.fig,],
  tt.avg[idx.tt.fig,]
)

figBC.norm.avg <- ddply(figBC,'country',function(x){
  x$norm.entropy <- x$avg.entropy/max(x$avg.entropy)
  return(x)})

figBC.norm.avg$model <- factor(
  figBC.norm.avg$model,
  levels = c('Train','Prediction')
)
p.figD<- ggplot(figBC.norm.avg,
                aes(y=country,x=ym)) +
  geom_tile(aes(fill=norm.entropy),
            col='black',width=0.85,height=0.9) +
  scale_y_discrete(limit=levels(tr.avg$country)) +
  facet_grid(.~model,scales = 'free_x',space='free') +
  scale_fill_gradient(name = 'Normalized \nEntropy of LS',
                      high = "#2ca089ff",
                      low = "#F7F7F7") +
  theme_pubr(legend = 'right') + 
  xlab('Month') + ylab('Country') +
  theme(axis.text.x = element_text(angle = 45,vjust = 1,hjust = 1))


pdf('./figures/Fig01-D.pdf', width = 8,height = 5.5)
p.figD
dev.off()
