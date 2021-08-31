#=====================
#' Author: Rintu Kutum
#' Date: 29 Jun 2021, 11.30 AM
#' Affiliation: TavLab, Department of Computational Biology, IIIT-Delhi
#' Usage:
#' 	Rscript 03-A1-augur2covseq.R "2021-04"
#===================== STATUS
#   1. Rscript 03-A1-augur2covseq.R "2021-04"  #-> DONE
#   2. Rscript 03-A1-augur2covseq.R "2021-05"  #-> DONE
#   3. Rscript 03-A1-augur2covseq.R "2021-06"  #-> DONE

args <- commandArgs(trailingOnly = TRUE)
#args[1] = "2021-04"
#yearMonthSubmission <- "2021-04"
yearMonthSubmission = args[1]
#print(yearMonthSubmission)

augus.path <- paste0("./data/augus-format/",yearMonthSubmission,"/")
augus.files <- list.files(augus.path,full.names=TRUE)
if(length(augus.files) !=0){
  message("......\n",augus.path, " contains ",length(augus.files)," files\n......\n")
}else{
  stop('Please check the path')
}
dir.create('./data/augus-format/temp/',showWarnings=FALSE)
tar2gisaid <- function(tar.file, copy.dir){
  cmd <- paste('tar -xvf ',tar.file, ' -C ./data/augus-format/temp/',sep='')
  system(cmd)
}

processTAR <- function(x){
  sapply(x, tar2gisaid)
  cat('\nExtracted to the dir : "./data/augus-format/temp/"\n')
}
processTAR(augus.files)

#--------- Processing metadata
metadata.files <- list.files('./data/augus-format/temp/',pattern='metadata',full.names=TRUE)
metadata <- lapply(metadata.files,function(x){
  read.delim(x,sep='\t',stringsAsFactors=FALSE)
  })

metadata.month <- do.call('rbind',metadata)
dir.create('./data/metadata/',showWarnings=FALSE)
metadata.name <- paste0('./data/metadata/',yearMonthSubmission,"-metadata.RData")
save(metadata.month,file=metadata.name)

#-------- Parallel processing
message("\n=========== CoVseq PREPARE ===========\n")
library(doMC)
#-------- Prepare for CoVseq pipeline
library("seqinr")
fa.files <- list.files('./data/augus-format/temp/',pattern='fasta',full.names=TRUE)
covseq.path <- paste0('data/covseq-format/',yearMonthSubmission,'/')
dir.create(covseq.path,showWarnings=FALSE)
registerDoMC(24)
fixFasta <- foreach(i=1:length(fa.files))%dopar%{
  cat(i,' Processing ',fa.files[i],' is done...\n')
  fa.val <- read.fasta(
    fa.files[i], as.string=TRUE, forceDNAtolower=FALSE)
  fixAnnoName <- function(x){
     gsub("\\/","_",x)
  }
  num.id <- strsplit(strsplit(
    fa.files[i], split="\\/")[[1]][6], split="\\.")[[1]][1]
  covseq.input <- paste0(covseq.path,num.id,'-fixed.fasta')
  write.fasta(fa.val,
    as.character(sapply(names(fa.val),fixAnnoName)),covseq.input)
}
registerDoSEQ()
system('rm -r data/augus-format/temp/')

message("\n=========== CoVseq RUN ===========\n")
#-------- CoVseq run parallel
setwd('./covseq')
fa.path <- paste0('../',covseq.path)
fa.locs <- list.files(fa.path,full.names=TRUE)

registerDoMC(24)
parRUN <- foreach(i=1:length(fa.locs))%dopar%{
  fa.loc <- fa.locs[i]
  cmd <- paste0(
    "python annotation/annotation.py --fasta ",
     fa.loc,
     " --out_dir ./results/",
     yearMonthSubmission,
     "/ ", "--snpeff False")
  system(cmd)
}
registerDoSEQ()
message("\n===========\n=========== CoVseq DONE ===========\n===========\n")
setwd('../')

