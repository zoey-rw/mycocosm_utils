library(tidyverse)

# Get all the NCBI taxIDs from Mycocosm, check for any not already downloaded from GOLD

# Read in previously-generated info table from GOLD (create_fungal_genome_list_GOLD.R)
genome_info_in <- read_tsv("/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/genomes/fungal_genomes/acc_table.tsv")
genome_info_in$file_path = file.path("/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/genomes/fungal_genomes/genbank/fungi", genome_info_in$ncbi_genbank_assembly_accession)

# Read in Mycocosm-published list (downloaded manually from site)
myco_in <- read_csv("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/genomes/fungal_genomes/mycocosm_unfiltered_list.txt",
										col_names = c("row", "name", "portal", "NCBI_TaxID", "assembly length", "gene_count", "is_public", "is_published", "is_superseded","superseded by", "publications", "pubmed_id","doi_id"), skip = 1)


downloaded_file_info = genome_info_in[match(myco_in$NCBI_TaxID, genome_info_in$`ORGANISM NCBI TAX ID`),]

# Which mycocosm taxa are already downloaded?
# myco_is_downloaded = myco_in[match(genome_info_in$`ORGANISM NCBI TAX ID`, myco_in$NCBI_TaxID),]


# List genomes already downloaded
already_downloaded <- list.files("/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/genomes/fungal_genomes/genbank/fungi",
																 full.names = T, recursive = T, pattern = ".fna.gz")
downloaded_accession_no = basename(dirname(already_downloaded))


# Read summary files from NCBI ftp sites - use to give taxIDs to genomes
genbank_summary <- read.csv("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/Struo2/fungal_genomes/assembly_summary_genbank.txt", skip = 1, sep="\t", comment.char = "")
ncbi_summary_euk <- read_tsv("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/fungal_genomes/genome_reports_eukaryotes.txt")

# downloaded_summary = genbank_summary[genbank_summary$X.assembly_accession %in% accession_no,]
# missing_from_summary = accession_no[!accession_no %in% genbank_summary$X.assembly_accession]

# Get the taxIDs for downloaded genomes
downloaded_taxID1 = ncbi_summary_euk$TaxID[match(downloaded_accession_no,ncbi_summary_euk$`Assembly Accession`)]
downloaded_taxID2 = genbank_summary$taxid[match(downloaded_accession_no,genbank_summary$X.assembly_accession)]
downloaded_key = cbind.data.frame(downloaded_accession_no, downloaded_taxID1, downloaded_taxID2, local_fp=already_downloaded)
downloaded_key$taxID = ifelse(is.na(downloaded_key$downloaded_taxID1), downloaded_key$downloaded_taxID2, downloaded_key$downloaded_taxID1)

ready_genomes = merge(myco_in, downloaded_key, by.x="NCBI_TaxID", by.y="taxID", all.x=T)

# Get taxIDs for Mycocosm taxa that have no downloaded genomes
missing_to_download = anti_join(myco_in, downloaded_key,  by=join_by(NCBI_TaxID==taxID)) %>% filter(is_published=="Y")

# A higher % are in the broader genbank eukaryotic genome summary, but the accession summary file has the actual ftp paths...
download_links = ncbi_summary_euk$NCBI_TaxID %in% ncbi_summary_euk
download_links = genbank_summary[match(missing_to_download$NCBI_TaxID, genbank_summary$taxid),]$ftp_path

# Create a list to re-try downloads
missing_to_download_ids <- unique(missing_to_download$NCBI_TaxID) %>% unique() %>%  paste(sep="", collapse="\n")

# Save list for command-line tool (ncbi-genome-download)
writeLines(missing_to_download_ids,"/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/fungal_genomes/missing_taxids.txt")


# Check that newly-downloaded taxa also have metadata
newly_downloaded = read_tsv("/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/fungal_genomes/missing_ncbi_metadata_table.csv")
newly_downloaded$taxid %in% ncbi_summary_euk$TaxID
newly_downloaded$taxid %in% genbank_summary$taxid

