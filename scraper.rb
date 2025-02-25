require 'nokogiri'
require 'open-uri'
require 'sqlite3'
require 'logger'
require 'date'

# Initialize the logger
logger = Logger.new(STDOUT)

# Define the URL of the page
url = 'https://www.circularhead.tas.gov.au/council-services/development/planning'

# Step 1: Set up a User-Agent to simulate a real browser
begin
  logger.info("Fetching page content from: #{url}")
  page_html = open(url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36").read
  logger.info("Successfully fetched page content.")
rescue => e
  logger.error("Failed to fetch page content: #{e}")
  exit
end

# Step 2: Parse the page content using Nokogiri
doc = Nokogiri::HTML(page_html)

# Step 3: Initialize the SQLite database
db = SQLite3::Database.new "data.sqlite"

# Create table
db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS circularhead (
    id INTEGER PRIMARY KEY,
    description TEXT,
    date_scraped TEXT,
    date_received TEXT,
    on_notice_to TEXT,
    address TEXT,
    council_reference TEXT,
    applicant TEXT,
    owner TEXT,
    stage_description TEXT,
    stage_status TEXT,
    document_description TEXT,
    title_reference TEXT
  );
SQL

# Define variables for storing extracted data for each entry
address = ''  
description = ''
on_notice_to = ''
title_reference = ''
date_received = ''
council_reference = ''
applicant = ''
owner = ''
stage_description = ''
stage_status = ''
document_description = ''
date_scraped = Date.today.to_s

# Step 4: Extract data for each entry
doc.css('li.link-listing__no-icon').each do |row|
  # Extract the title from the <a> tag
  title_reference = row.at_css('a').text.strip

  # Extract council_reference, address, and description
  council_reference = title_reference.split(' - ').first.strip
  address = title_reference.split(' - ')[1..-2].join(' - ').strip
  description = title_reference.split(' - ').last.split('(').first.strip

  # Log the extracted data for debugging purposes
  logger.info("Extracted Data: Address: #{address}, Council Reference: #{council_reference}, Description: #{description}")

  # Step 5: Ensure the entry does not already exist before inserting
  existing_entry = db.execute("SELECT * FROM circularhead WHERE council_reference = ?", council_reference)
  
  if existing_entry.empty? # Only insert if the entry doesn't already exist
    # Save data to the database
    db.execute("INSERT INTO circularhead (address, council_reference, description, date_scraped) 
      VALUES (?, ?, ?, ?)", [address, council_reference, description, date_scraped])

    logger.info("Data for #{council_reference} saved to database.")
  else
    logger.info("Duplicate entry for document #{council_reference} found. Skipping insertion.")
  end
end

# Finish
logger.info("Data has been successfully inserted into the database.")
