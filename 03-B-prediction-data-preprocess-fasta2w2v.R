#=====================
#' Author: Rintu Kutum
#' Date: 30 Jun 2021, 11.30 AM
#' Affiliation: TavLab, Department of Computational Biology, IIIT-Delhi
#' Usage:
#' 	Rscript fasta2w2v.R "2021-04"
#===================== STATUS
#   1. Rscript 03-B-prediction-data-preprocess-fasta2w2v.R "2021-04"  #-> DONE // nohup ./03-C-run-2021-04-fa2w2v.sh
#   2. Rscript 03-B-prediction-data-preprocess-fasta2w2v.R "2021-05"  #-> DONE // nohup ./03-C-run-2021-05-fa2w2v.sh
#   3. Rscript 03-B-prediction-data-preprocess-fasta2w2v.R "2021-06"  #-> DONE // nohup ./03-C-run-2021-06-fa2w2v.sh

args <- commandArgs(trailingOnly = TRUE)
#args[1] = "2021-04"
# yearMonthSubmission <- "2021-04"
# yearMonthSubmission <- "2021-05"
yearMonthSubmission = args[1]

covseq.anno.path <- paste0('covseq/results/',yearMonthSubmission)
covseq.anno.file <- list.files(
  covseq.anno.path, pattern='.tsv', recursive=TRUE, full.names=TRUE
)
library(doMC)
registerDoMC(36)
covseq.bind <- foreach(i=1:length(covseq.anno.file))%dopar%{
  if(i == 1){
    cat('\n===========\nProcessing of covseq annnotation is started!\n===========\n')
  }
  if(i %% 10000 == 0){
    message('\n===========\nProcessing of covseq ',i, ' annnotations done!\n===========\n')
  }
  if(i == length(covseq.anno.file)){
    cat('\n===========\nProcessing of covseq annnotation is finished!\n===========\n')
  }
  xx <- strsplit(covseq.anno.file[i], split='\\/')[[1]]
  strain.recov <- xx[length(xx)-1]
  anno.data <- read.delim(
      covseq.anno.file[i], stringsAsFactors=FALSE, sep='\t'
  )
  anno.data$strain <- strain.recov
  anno.data
}
registerDoSEQ()

strain.names <- sapply(covseq.bind,function(x){unique(x$strain)})
names(covseq.bind) <- strain.names

#---- READ STRAIN SEQUENCES

covseq.seq.path <- paste0('data/covseq-format/',yearMonthSubmission)
covseq.fasta.files <- list.files(
  covseq.seq.path, pattern='-fixed.fasta', full.names=TRUE
)

getRegion <- function(x,seq){
  start <- x['Start']
  end <- x['End']
  if(grepl(',',start)){
    starts = strsplit(start,split='\\,')[[1]]
    ends = strsplit(end,split='\\,')[[1]]
    seq1 <- paste(seqinr::getFrag(seq,starts[1],ends[1]),collapse='')
    seq2 <- paste(seqinr::getFrag(seq,starts[2],ends[2]),collapse='')
    output <- paste0(seq1,seq2)
  }else{
    output <- paste(seqinr::getFrag(seq,start,end),collapse='')
  }
  return(output)
}
# i=28
registerDoMC(36) # run-time 10-15 mins approx
w2v.data <- foreach(i=1:length(covseq.fasta.files))%dopar%{
  message(i, '. Processing ', covseq.fasta.files[i],' ....!')
  covseq.5k.fa <- seqinr::read.fasta(
    covseq.fasta.files[i], as.string=TRUE,
    forceDNAtolower=FALSE
  )
  common.strain <- intersect(names(covseq.5k.fa), strain.names)
  strain.tsv <- covseq.bind[common.strain]
  strain.fa <- covseq.5k.fa[common.strain]
  strain.ModData <- foreach(j=1:length(strain.fa))%do%{
    str.fa <- strain.fa[[j]]
    str.tsv <- strain.tsv[[j]]
    # check end and sequence length
    # hCoV-19_Chile_RM-75300_2021
    idx.ok <- c(TRUE,
      as.numeric(str.tsv$End[-1]) < nchar(str.fa)
    )
    str.tsv <- str.tsv[idx.ok,]
    str.frags <- apply(str.tsv,1,getRegion,seq=str.fa)
    str.tsv$Sequence <- str.frags
    str.tsv$Sequence_Length <- nchar(str.tsv$Sequence)
    str.tsv$Triples_Count <- str.tsv$Sequence_Length/3
    x.out <- str.tsv$Sequence_Length %% 3
    x.div <- x.out == 0
    str.tsv$DividesBy3 <- x.div
    str.tsv
  } # 4 mins approx
  strain.ModData
}
registerDoSEQ()

w2v.data.bind <- do.call('c',w2v.data)
st.names <- sapply(w2v.data.bind,function(x){unique(x$strain)})
rm(w2v.data.bind)

#---- LOAD METADATA
metadata.path <- paste0('data/metadata/',yearMonthSubmission,'-metadata.RData')
load(metadata.path)

meta.colnames <- c(
  'gisaid_epi_isl', 'date', 'region', 'country', 'division',
  'location', 'region_exposure', 'country_exposure', 'division_exposure',
  'host', 'age', 'sex', 'pangolin_lineage', 'GISAID_clade', 'date_submitted'
)

st.names <- gsub('\\_','/',st.names)
common.st.names <- intersect(st.names,metadata.month$strain)
common.st.names <- gsub('\\/','_',common.st.names)
#--- 15 mins approx (Need to shift the code to above)
registerDoMC(36)
w2v.input <- foreach(i=1:length(w2v.data))%dopar%{
  message(i,'. Processing ',i,'/',length(w2v.data))
  str.data = w2v.data[[i]]
  str.names <- sapply(str.data,function(x){unique(x$strain)})
  str.process <- intersect(str.names,common.st.names)
  str.idx <- which(str.process %in% str.names)
  str.DF <- foreach(j=1:length(str.idx))%do%{
    str.df <- str.data[str.idx[j]][[1]]
    str.df$strain <- gsub('\\_','/',str.df$strain)
    str.name <- unique(str.df$strain)
    idx <- str.name ==  metadata.month$strain
    if(length(which(idx)) != 0){
      str.metadata <- metadata.month[idx,meta.colnames]
      str.meta <- apply(str.metadata,2,function(x,times){rep(x,times)},times=nrow(str.df))
      colnames(str.meta)[2] <- 'Collection_Date'
      str.output <- cbind(str.df,str.meta)
    }else{
      str.output <- NULL
    }
    str.output
  }
  str.DF[!sapply(str.DF,is.null)]
}
registerDoSEQ()

w2v.list <- do.call('c',w2v.input)

countries <- sapply(w2v.list,function(x){unique(x$country)})

tb.country <- table(countries)
registerDoMC(16)
w2v.country <- foreach(i=1:length(tb.country))%dopar%{
  country.name <- names(tb.country[i])
  idx <- countries %in% country.name
  message(i,'. Processing ', country.name, ' ...')
  plyr::ldply(w2v.list[idx])
}
registerDoSEQ()
names(w2v.country) <- names(tb.country)

w2v.country.path <- paste0('data/w2v-MY-summission/',yearMonthSubmission)
dir.create(w2v.country.path,showWarnings=FALSE,recursive=TRUE)
registerDoMC(16)
runPAR <- foreach(i=1:length(w2v.country))%dopar%{
  month.year <- as.character(w2v.country[[i]]$Collection_Date)
  w2v.country[[i]]$MY <- sapply(month.year,function(x){
    paste(strsplit(x,split='\\-')[[1]][1:2],collapse='-')}
  )
  tb.MY <- table(w2v.country[[i]]$MY)
  w2v.country.MY <- plyr::dlply(w2v.country[[i]],'MY')
  runOUT <- foreach(j=1:length(w2v.country.MY))%do%{
    message(i,'.',j,' ::: ', 'Processing Collection Date = ', names(w2v.country)[i],
      ' ', names(w2v.country.MY)[j], ' ::: #strain = ',
      tb.MY[names(w2v.country.MY)[j]]
    )
    subpath.country <- paste0(
      w2v.country.path,
      '/CM-',names(w2v.country.MY)[j]
    )
    dir.create(subpath.country,showWarnings=FALSE)
    w2v.country.filename <- paste0(
      subpath.country, '/',
      gsub('[[:space:]]','',names(w2v.country)[i]),
      '-',
      tb.MY[names(w2v.country.MY)[j]],
      '.csv'
    )
    write.csv(w2v.country.MY[[j]],w2v.country.filename,row.names=FALSE)
  }
}
registerDoSEQ()

