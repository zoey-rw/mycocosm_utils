# Attempting to match the ITS sequences a bit more reliably using NCBI taxIDs
# Limits the available genomes to 469

library(data.table)
library(Biostrings)
library(readr)

nr_taxid_mapping = read_tsv("its_acc_taxids.txt",
															col_names = c("NCBI_NR_accession","NCBI_TaxID"))


mycocosm_in <- read.csv("https://mycocosm.jgi.doe.gov/ext-api/mycocosm/catalog/download-group?flt=&seq=all&pub=all&grp=fungi&srt=released&ord=desc", 
check.names = F, col.names = c("row", "organism_name", "portal", "NCBI_TaxID", "assembly_length", "gene_count", "is_restricted","is_public", "is_published", 
"is_superseded","superseded by", "publications", "pubmed_id","doi_id"))

# Mycocosm reformat
mycocosm_in$organism_name = gsub('\\"',"",mycocosm_in$organism_name)
mycocosm_in$strain = gsub(' v1.0| v2.0',"",mycocosm_in$organism_name)
mycocosm_in$species =  word(mycocosm_in$strain, 1, 2)
mycocosm_in$genus = word(mycocosm_in$species, 1, 1)

intersect(colnames(mycocosm_in), colnames(nr_taxid_mapping)) # Matching based on NCBI_taxid rather than species name 
mycocosm_its_merge = merge(mycocosm_in, nr_taxid_mapping, all.x=T)

table(is.na(mycocosm_its_merge$NCBI_NR_accession))

matched_by_taxid = mycocosm_its_merge %>% filter(!is.na(mycocosm_its_merge$NCBI_NR_accession))

table(matched_by_taxid$is_restricted) # 768 genomes unrestricted
table(matched_by_taxid$is_published) # 469 genomes published
