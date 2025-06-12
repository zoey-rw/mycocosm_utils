# Mycocosm ITS Sequence Matching

This repository contains scripts for matching NCBI ITS (Internal Transcribed Spacer) sequences with fungal genomes from the Mycocosm database. The workflow identifies published fungal genomes that have corresponding ITS sequences available in NCBI's RefSeq database.

## Scripts

### 01_get_refseq_its.r
**Purpose**: Downloads NCBI ITS sequences and performs initial matching with Mycocosm genomes based on species names.

**Outputs**:
- `mycocosm_its.csv`: Table of matched Mycocosm genomes with ITS sequences
- `nr_accessions_its.txt`: List of NCBI accession numbers for genus-matched ITS sequences

### 02_get_ncbi_taxids.sh
**Purpose**: Retrieves NCBI taxonomic IDs for the ITS sequence accessions.
- Processes accession numbers from `nr_accessions_its.txt`
- Queries NCBI E-utilities to fetch taxonomic IDs
- Creates mapping between accession numbers and taxonomic IDs

**Output**:
- `its_acc_taxids.txt`: Tab-separated file mapping accession numbers to taxonomic IDs

### 03_match_its_to_mycocosm.R
**Purpose**: Performs improved matching using NCBI taxonomic IDs (instead of species names)
- For successfully downloaded files, reads taxonomic ID mapping from previous script
- Merges with Mycocosm data using NCBI TaxID

## Results
- **1,626** total Mycocosm genomes are "published"
- **1,023** Mycocosm genomes have ITS sequences at the species level
- **644** published genomes have species-level ITS sequences
- **87** published genomes have strain-level ITS sequences
- **469** genomes can be matched using taxonomic IDs
