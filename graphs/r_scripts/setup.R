# Instalar (só uma vez)
# install.packages(c("pagoo","ggplot2","patchwork","pheatmap","UpSetR","data.table","readr","dplyr","igraph","ape","phangorn"))
# install.packages("remotes")
# remotes::install_github("iferres/pagoo")

library(pagoo)
library(ggplot2)
library(patchwork)
library(pheatmap)
library(UpSetR)
library(data.table)
library(readr)
library(dplyr)
library(igraph)
library(ape)
library(phangorn)
library(stringr)
library(reshape2)
library(viridis)
library(tidyverse)


# caminhos (ajuste para o seu diretório)
setwd("c:/Users/Matheus/Documents/UFF/ic/repository/automation/all_maribacter/output/all_maribacter_strict_mafft/")
panaroo_dir <- getwd()
gpa_csv <- file.path(panaroo_dir, "gene_presence_absence.csv")
gpa_rtab <- file.path(panaroo_dir, "gene_presence_absence.Rtab")
summary_txt <- file.path(panaroo_dir, "summary_statistics.txt")
core_aln <- file.path(panaroo_dir, "core_gene_alignment.aln")
entropy_csv <- file.path(panaroo_dir, "alignment_entropy.csv")
final_gml <- file.path(panaroo_dir, "final_graph.gml")
clusters <- file.path(panaroo_dir, "combined_protein_cdhit_out.txt.clstr")
gene_data <- file.path(panaroo_dir, "gene_data.csv")
metadata <- "c:/Users/Matheus/Documents/UFF/ic/repository/automation/all_maribacter_graphs/r_scripts/metadados.csv"

# Mova os arquivos *.gff para um único diretório
# Os nomes não devem ser alterados
# O Pagoo associa os nomes dos arquivos com o cabeçalho de gpa_csv
gff_dir <- "c:/Users/Matheus/Documents/UFF/ic/repository/automation/all_maribacter_graphs/r_scripts/gff_files"
gff_paths <- Sys.glob(file.path(gff_dir, "*.gff"))

graphs_dir <- "c:/Users/Matheus/Documents/UFF/ic/repository/automation/all_maribacter_graphs/graphs/"