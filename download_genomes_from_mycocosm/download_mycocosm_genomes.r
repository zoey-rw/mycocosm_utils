
## Load package environment -----------------------------

library(httr)
library(jsonlite)
library(RSelenium)
library(rvest)
library(tidyverse)



fprof <- makeFirefoxProfile(list(browser.download.manager.showWhenStarting=FALSE,
                                 browser.download.dir = "/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/mycocosm_genomes",
                                 browser.helperApps.neverAsk.saveToDisk="text/csv.fasta.gz",
                                 browser.download.folderList = 2L))

rd <- rsDriver(browser = "firefox",chromever = NULL,extraCapabilities = fprof, port=5003L)
remDr <- rd$client


#172.17.0.6

# remDr <- remoteDriver(
#   remoteServerAddr = "localhost",
#   port = 5555,
#   browserName = "firefox",
#   chromever = NULL)
# 
# remDr <- remoteDriver(
#   remoteServerAddr = "172.17.0.2",
#   port = 4444)
remDr$open()
remDr$close() # Make sure driver is closed before running the below function

## Load Data to run -----------------------------

output.folder = "/projectnb/talbot-lab-data/zrwerbin/soil_genome_db/mycocosm_genomes"

#download_from_links(download_df, output.folder)

list_already_downloaded = list.files("/projectnb2/talbot-lab-data/zrwerbin/soil_genome_db/mycocosm_genomes", 
                                     pattern = "fasta.gz")

mycocosm_data_in <- read.csv("https://mycocosm.jgi.doe.gov/ext-api/mycocosm/catalog/download-group?flt=&seq=all&pub=all&grp=fungi&srt=released&ord=desc", check.names = F, col.names = c("row", "Name", "ID", "NCBI_TaxID", "assembly length", "gene_count", "is_public", "is_published", "is_superseded","superseded by", "publications", "pubmed_id","doi_id"), skip = 1)
mycocosm_data_in$Name = gsub('\\"',"",mycocosm_data_in$Name)
mycocosm_data_in$Go.Download.Link = str_c('https://genome.jgi.doe.gov/portal/', mycocosm_data_in$ID, 
                                 "/download/", mycocosm_data_in$ID, "_AssemblyScaffolds_Repeatmasked.fasta.gz")

download_df <- mycocosm_data_in %>% filter(is_published=="Y")

# Subset to only those missing from our downloaded files
download_df_subset = download_df[which(!basename(download_df$Go.Download.Link) %in% list_already_downloaded),]


for (r in 1:nrow(download_df_subset)){
  browseURL(download_df_subset$Go.Download.Link[r])
  Sys.sleep(3)
}

for (r in 1:nrow(download_df_subset)){
  download_from_links(download_df_subset[r,], output.folder)
  
}


#identical(download_df$Go.Download.Link, download_df$link_attempt)
## Pull Taxa ID function (Run these lines to create the function in your R environment) -------------
download_from_links <- function(run.list, save.folder) {
  
  # Set length of loop from load data
  run.length <- run.list %>%
    row.names() %>%
    length()
  
  # Start loop to pull data for each taxa name
  for (k in 1:run.length) {
    # k <- 1
    # run.list <- id.list
    # save.folder = output.folder
    # if the first time running through the loop, start the remote driver
    if(k==1){
      remDr$open()
      remDr$screenshot(TRUE)
    }
    
    
    # if the first run navigate to a link on the website to prompt the login page
    if(k==1) {
      initial.link <- 'https://genome.jgi.doe.gov/portal/Aaoar1/Aaoar1.download.html'
      remDr$navigate(initial.link)
      remDr$screenshot(TRUE)
    }
    
    # if the first time running through the loop, run through a login protocol
    if(k==1){
      # click the login button
      login.button <- '//*[@id="login"]'
      webElem = remDr$findElement('xpath', login.button)
      webElem$clickElement()
      Sys.sleep(2)
      remDr$screenshot(TRUE)

      # fill the email box with your login email
      login.mail <- "zrwerbin@bu.edu" # set your login email
      email.box <- '//*[@id="login"]'
      webElem = remDr$findElement('xpath', email.box)
      webElem$sendKeysToElement(list(login.mail))
      remDr$screenshot(TRUE)
      
      # fill the password box with your login password
      login.password <- "qr5VU.j5.3dnYFi" # set your login password (please change from my password)
      password.box <- '//*[@id="password"]'
      webElem = remDr$findElement('xpath', password.box)
      webElem$sendKeysToElement(list(login.password))
      remDr$screenshot(TRUE)
      
      # press the sign in button
      sign.in.button <- '//*[@id="home"]/p/input'
      webElem = remDr$findElement('xpath', sign.in.button)
      webElem$clickElement()
      Sys.sleep(2)
      remDr$screenshot(TRUE)
      
    }
    
    
    # Pull the Taxa code for the loop iteration from the loaded data
    run.id <- run.list[k,'ID']   
    # Pull the Taxa name for the loop iteration from the loaded data
    run.name <- run.list[k,'Name']
    go.link <- run.list[k,'Go.Download.Link']
    
    
    # Create url to Taxa XML directory using the Taxa ID
    xml.link <- str_c('https://genome.jgi.doe.gov/portal/ext-api/downloads/get-directory?organism=',
                      run.id,
                      '&organizedByFileType=false')
    
    # Navigate to the Taxa XML directory
    Sys.sleep(4)
    remDr$navigate(xml.link)
    Sys.sleep(4)
    
    # Actually download the file (will just go to the default download location)
    Sys.sleep(2)
    remDr$navigate(go.link)
    # Print a message with the loop iteration and the Taxa ID to keep track as you run 
    print(str_c(k, '_',run.id,"_downloaded"))
  }
    
  return()
  
}


remDr$navigate(go.link)


