#----------------------
# Author: Rintu Kutum
#----------------------
rm(list=ls())
#----------------------
# train embeddings
embedding.model01 <- readr::read_csv(
  'data/embeddings/word2vec-spike-all-countries-36-VS_updated.csv'
)
idx.rm <- grep("2021-04",embedding.model01$Collection_Date)

colnames(embedding.model01)[c(2,4)] <- c(
  "gisaid_epi_isl", "country")

embedding.model01 <- embedding.model01[-idx.rm,]
colnames(embedding.model01)[5:40] <- as.character(1:36)
idx.dup <- check.duplicate(
  embedding.model01$gisaid_epi_isl,
  return.value = TRUE)
sf_v1_embedd <- embedding.model01[!idx.dup,colNames]

sf_v1_embedd$ym <- sapply(
  sf_v1_embedd$Collection_Date,
  getYM
)
sf_v1_embedd$model <- 'sfv1:train'
#----------------------
# prediction embeddings
comb_embedd <- readr::read_csv(
  'data/embeddings/combined.csv'
)
colNames <- c(
  'gisaid_epi_isl', 'country', 'Collection_Date',
  as.character(1:36)
)
comb_embedd_only <- comb_embedd[,colNames]

check.duplicate <- function(x,return.value=FALSE){
  idx.dup <- duplicated(x)
  print(table(idx.dup))
  if(return.value){
    return(idx.dup)
  }
}

idx.dup <- check.duplicate(comb_embedd_only$gisaid_epi_isl,return.value = TRUE)
dup_gisaid <- comb_embedd_only$gisaid_epi_isl[idx.dup]
dup_loc <- comb_embedd_only$gisaid_epi_isl %in% dup_gisaid
getYM <- function(x){
  paste(
    strsplit(as.character(x),split = '\\-')[[1]][1:2],
    collapse = '-')
}
comb_embedd_only$ym <- sapply(
  comb_embedd_only$Collection_Date,
  getYM
)

comb_embedd_only <- comb_embedd_only[!idx.dup,]

comb_embedd_only$country[comb_embedd_only$country %in% c("United States","Usa")] <- "USA"
comb_embedd_only$country[comb_embedd_only$country == "belgium"] <- "Belgium"
comb_embedd_only$country[comb_embedd_only$country == "United Kingdom"] <- 'UK'
comb_embedd_only$country <- gsub(' ','-',comb_embedd_only$country)

comb_embedd_only$model <- 'sfv1:prediction'
#----------------------
# train + prediction embeddings of strainflow v1
strainflow_v1 <- rbind(
  sf_v1_embedd,
  comb_embedd_only
)
idx.dup <- check.duplicate(strainflow_v1$gisaid_epi_isl,TRUE)
dup_gisaid <- unique(strainflow_v1$gisaid_epi_isl[idx.dup])
# remove the duplicates from prediction
idx.rm <- comb_embedd_only$gisaid_epi_isl %in% dup_gisaid
comb_embedd_only <- comb_embedd_only[!idx.rm,]
strainflow_v1 <- rbind(
  sf_v1_embedd,
  comb_embedd_only
)
colnames(strainflow_v1)[4:39] <- paste0('LD',1:36)

save(strainflow_v1,file='data/latent-space/strainflow_v1.RData')

