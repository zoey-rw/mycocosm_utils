## Generates a list of NCBI accessions for ITS sequences associated with Mycocosm fungal genomes

## Pull ITS sequence file from NCBI - command line
# wget ftp://ftp.ncbi.nlm.nih.gov/refseq/TargetedLoci/Fungi/
#unzip fungi.ITS.fna.gz # may vary by machine

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("Biostrings")

library(data.table)
library(Biostrings)
library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)


## Matching NCBI entries with Mycocosm
 
# Read in ITS loci downloaded from NCBI ftp site (above)
its_sequences_in <- readDNAStringSet("fungi.ITS.fna")
its_df <- data.frame(seq_name = names(its_sequences_in), sequence = paste(its_sequences_in)) %>%
	separate(seq_name, sep = "^\\S*\\K\\s+", into=c("ID","organism_name")) # separate at first space

# Read in Mycocosm-published list (downloaded manually from site)
mycocosm_in <- read_csv("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/genomes/fungal_genomes/mycocosm_unfiltered_list.txt",
											col_names = c("row", "organism_name", "portal", "NCBI_TaxID", "assembly length", "gene_count", "is_public", "is_published", "is_superseded","superseded by", "publications", "pubmed_id","doi_id"), skip = 1)

mycocosm_in <- read.csv("https://mycocosm.jgi.doe.gov/ext-api/mycocosm/catalog/download-group?flt=&seq=all&pub=all&grp=fungi&srt=released&ord=desc", 
check.names = F, col.names = c("row", "organism_name", "portal", "NCBI_TaxID", "assembly_length", "gene_count", "is_restricted","is_public", "is_published", 
"is_superseded","superseded by", "publications", "pubmed_id","doi_id"))
mycocosm_in$organism_name = gsub('\\"',"",mycocosm_in$organism_name)

# Reformat names in both dataframes to match
# This assumes all species have exactly two words... not the best method

# ITS loci reformat - ideally we'd pull the taxid from each ncbi listing (using the NR accession)
its_df$strain = gsub(" ITS region; from TYPE material| ITS region; from reference material","",its_df$organism_name)
its_df$species = word(its_df$strain, 1, 2)
its_df$genus = word(its_df$species, 1, 1)

# Mycocosm reformat
mycocosm_in$organism_name = gsub('\\"',"",mycocosm_in$organism_name)
mycocosm_in$strain = gsub(' v1.0| v2.0',"",mycocosm_in$organism_name)
mycocosm_in$species =  word(mycocosm_in$strain, 1, 2)
mycocosm_in$genus = word(mycocosm_in$species, 1, 1)


## Identifying suitable genomes for matching

# Label Mycocosm genomes with ITS sequences, varying by "published" status 

mycocosm_in$have_species_its = ifelse(mycocosm_in$species %in% its_df$species, T, F)
mycocosm_in$have_strain_its = ifelse(mycocosm_in$strain %in% its_df$strain, T, F)
mycocosm_in$is_published_and_has_its = ifelse(mycocosm_in$have_species_its==T & mycocosm_in$is_published=="Y", T, F)
mycocosm_in$is_published_and_has_strain_its = ifelse(mycocosm_in$have_strain_its==T & mycocosm_in$is_published=="Y", T, F)
mycocosm_in$is_unrestricted_and_has_strain_its = ifelse(mycocosm_in$have_strain_its==T & mycocosm_in$is_restricted=="N", T, F)
mycocosm_in$is_unrestricted_and_has_its = ifelse(mycocosm_in$have_species_its==T & mycocosm_in$is_restricted=="N", T, F)

# table(mycocosm_in$is_published)
# # 1626 mycocosm genomes are published

# table(mycocosm_in$have_species_its)
# # 1023 mycocosm genomes have an ITS sequence at the species level

# table(mycocosm_in$is_published_and_has_its)
# # 644 mycocosm genomes have an ITS sequence at the species level AND are published

# table(mycocosm_in$is_published_and_has_strain_its)
# # 87 mycocosm genomes have an ITS sequence at the strain level AND are published
#
# # Subset to the 644 published genomes for output file
myco_subset = mycocosm_in %>% filter(is_published_and_has_its)
myco_subset$ITS_species = its_df[match(myco_subset$species, its_df$species),]$species
myco_subset$ITS_strain = its_df[match(myco_subset$species, its_df$species),]$strain
myco_subset$ITS_NR_accession = its_df[match(myco_subset$species, its_df$species),]$ID
myco_subset$ITS_sequence = its_df[match(myco_subset$species, its_df$species),]$sequence

# Write table of mycocosm genomes and matched ITS sequences
write.csv(myco_subset, "mycocosm_its.csv")


# Get accession numbers for all genus-matched ITS sequences
# Erring on the side of unnecessary downloads 
its_genus_subset = its_df %>% filter(genus %in% mycocosm_in$genus)
nr_acc_its <- its_genus_subset$ID %>% 
	unique() %>% 
	paste(sep="", collapse="\n")

writeLines(nr_acc_its, "nr_accessions_its.txt")

## For checking against UNITE? Maybe?

# unite_fasta = readDNAStringSet("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/mycocosm_matching/86E80475EDB915AC7173E82787BC0B73463A7690C30A91D715CF9BA0D51059BD/sh_general_release_dynamic_25.07.2023.fasta")
#
# unite_df <- data.frame(seq_name = names(unite_fasta), sequence = paste(unite_fasta)) %>%
# 	separate(seq_name, sep = "\\|", into=c("organism_name","ID2","ID3","reps","Lineage")) # separate at breaks
