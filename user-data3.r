#!/usr/bin/env Rscript

# Display warnings
options( warn = 1 )

print("")
print( "START" )
print("")

###############################################################################
#
# Use this scrip to populate the 'user-data' folder:
# https://github.com/devinit/digital-platform/tree/development/user-data
# The 'user-data' folder is linked to the live DH web app
# The primary location where the files in this folder are used is:
# http://data.devinit.org:8888/#!/data/methodology/ (staging)
# http://data.devinit.org/#!/data/methodology/ (live)
# There may be other locations where the DH web app pulls in files from this folder
# This is not confirmed at the moment
# For example, in a digital country profile, bottom of the page:
# http://data.devinit.org:8888/#!/country/united-kingdom (staging)
# http://data.devinit.org/#!/country/united-kingdom (live)
#
# This scripts uses the control file 'concepts.csv':
# https://github.com/devinit/digital-platform/blob/development/concepts.csv
# together with the raw .csv data files from folder 'country-year' and any subfolders within it:
# https://github.com/devinit/digital-platform/tree/development/country-year
# Each raw .csv data file from folder 'country-year' and any subfolder within it
# should be listed in the control file 'concepts.csv'
# In reality it may not be
# Also, there may be files in the 'concepts.csv' control file that do not exist
#
# Notes for stdout.txt:
# Discarding: won't include these in 'user-data', not to be provided
# Omitting: won't include these in 'user-data', file exists but no concepts.csv entry
#
# 2> stderr.txt
#
###############################################################################

# Package admin

# In the R console, check which packages you have
# installed.packages()[,c(1,c(3:4,15))]
#            Package      Version   Priority      NeedsCompilation
# base       "base"       "3.3.3"   "base"        NA
# boot       "boot"       "1.3-17"  "recommended" "no"
# class      "class"      "7.3-14"  "recommended" "yes"
# cluster    "cluster"    "2.0.6"   "recommended" "yes"
# codetools  "codetools"  "0.2-15"  "recommended" "no"
# compiler   "compiler"   "3.3.3"   "base"        NA
# datasets   "datasets"   "3.3.3"   "base"        NA
# foreign    "foreign"    "0.8-67"  "recommended" "yes"
# graphics   "graphics"   "3.3.3"   "base"        "yes"
# grDevices  "grDevices"  "3.3.3"   "base"        "yes"
# grid       "grid"       "3.3.3"   "base"        "yes"
# KernSmooth "KernSmooth" "2.23-15" "recommended" "yes"
# lattice    "lattice"    "0.20-34" "recommended" "yes"
# MASS       "MASS"       "7.3-44"  "recommended" "yes"
# Matrix     "Matrix"     "1.2-8"   "recommended" "yes"
# methods    "methods"    "3.3.3"   "base"        "yes"
# mgcv       "mgcv"       "1.8-16"  "recommended" "yes"
# nlme       "nlme"       "3.1-131" "recommended" "yes"
# nnet       "nnet"       "7.3-12"  "recommended" "yes"
# parallel   "parallel"   "3.3.3"   "base"        "yes"
# rpart      "rpart"      "4.1-10"  "recommended" "yes"
# spatial    "spatial"    "7.3-10"  "recommended" "yes"
# splines    "splines"    "3.3.3"   "base"        "yes"
# stats      "stats"      "3.3.3"   "base"        "yes"
# stats4     "stats4"     "3.3.3"   "base"        NA
# survival   "survival"   "2.41-2"  "recommended" "yes"
# tcltk      "tcltk"      "3.3.3"   "base"        "yes"
# tools      "tools"      "3.3.3"   "base"        "yes"
# utils      "utils"      "3.3.3"   "base"        "yes"

# Install packages (in a temporary location) that you need and don't already have
# Make sure that the folder where you want to install the packages exists first
# If it does not the installation will bail
# In this case: ~/user-data-test/packages
# install.packages(
#   c("reshape", "openxlsx")
#   , lib = "~/user-data-test/packages"
#   # UK, University of Bristol
#   , repos = "https://www.stats.bris.ac.uk/R/"
# )

# The downloaded source packages are in: '/tmp/Rtmpf6ABBY/downloaded_packages'

# You don't need to download "utils"
# "utils" is a base package, and should not be updated

# Load and attach the add-on packages that you need
library("openxlsx", lib.loc = "~/user-data-test/packages", warn.conflicts = TRUE)
library("reshape", lib.loc = "~/user-data-test/packages", warn.conflicts = TRUE)

###############################################################################

# Set up & clean up the working directory

# Specify the working directory i.e., the directory where the .csv data files are
# You will use the .csv data files in this directory to populate the 'user-data' folder
wd <- "~/user-data-test/user-data"
print("")
print( paste( "Working directory:                                     ", wd, sep = "" ) )
print("")

# Go to the working directory
setwd(wd)

# Delete everything in folder 'user-data', i.e., old 'user-data' files
# unlink: deletes the file(s) or directories specified by x
# x: a character vector with the names of the file(s) or directories to be deleted
# Wildcards (normally '*' and '?') are allowed
# recursive: logical
# Should directories be deleted recursively?
# force: logical
# Should permissions be changed (if possible) to allow the file or directory to be removed?
# full.names: logical
# If TRUE, the directory path is prepended to the file names to give a relative file path
# If FALSE, the file names (rather than paths) are returned
unlink(
  dir(wd, full.names = TRUE)
  , recursive = TRUE
)

###############################################################################

# This is where the main code begins

# List all files in 'country-year' folder
# list.files: produces a character vector of the names of files or directories in the named directory
# path: a character vector of full path names
# The default corresponds to the working directory, getwd()
# Tilde expansion (see path.expand) is performed
# Missing values will be ignored
# pattern: an optional regular expression
# Only file names which match the regular expression will be returned
# full.names: a logical value
# If TRUE, the directory path is prepended to the file names to give a relative file path
# If FALSE, the file names (rather than paths) are returned
# recursive: a logical value
# If TRUE traverses through the sub folders as well

# A length(absolute_file_name) (= 319) vector
# It contains the names of the files in the 'country-year' directory and any subdirectories within it
# In theory, all files in this directory (country-year) and any subdirectories within it
# should be listed in the control file concepts.csv
# In practice they are not
# This means that further down the line you have to put in a check
# to make sure that files that are not listed in the control file concepts.csv do not get processed
absolute_file_name <- list.files(
  "~/user-data-test/country-year"
  , pattern = "*.csv"
  , full.names = TRUE
  , recursive = TRUE
)
# print(absolute_file_name)

# Specify the reference directory i.e., the directory where the reference .csv data files are
reference_file_location = "~/user-data-test/reference/"
print("")
print( paste( "Working reference directory:                           ", reference_file_location, sep = "" ) )
print("")

# Specify the control file location
control_file = "~/user-data-test/concepts.csv"
print("")
print( paste( "Control file:                                          ", control_file, sep = "" ) )
print("")

# Read in the control file into a data frame
# A data frame is used for storing data tables
# It is a list of vectors of equal length
# In theory, the concepts.csv control file should list every data & reference file needed and used
# In reality, there are more data & reference files than listed in the concepts.csv control file
# Also, not all data & reference files listed in the concepts.csv control file are used and/or needed

# read.csv: reads a file in table format and creates a data frame from it
# Cases correspond to lines and variables to fields in the file
# header: a logical value indicating whether the file contains the names of the variables as its first line
# sep: the field separator character
# na.strings: a character vector of strings which are to be interpreted as 'NA' values
# check.names: logical. If 'TRUE' then the names of the variables in the data frame are checked to ensure that they are syntactically valid variable names
# If necessary they are adjusted (by 'make.names') so that they are, and also to ensure that there are no duplicates
# as.is: the default behavior of 'read.table' is to convert character variables (which are not converted to logical, numeric or complex) to factors
# The variable 'as.is' controls the conversion of columns not otherwise specified by 'colClasses'
# Its value is either a vector of logicals (values are recycled if necessary),
# or a vector of numeric or character indices which specify which columns should not be converted to factors
concepts <- read.csv(
  control_file
  , header = TRUE
  , sep = ","
  , na.strings = ""
  , check.names = FALSE
  , as.is = TRUE
)
# print(concepts)

# Get the number of rows and columns
# print(dim(concepts))
# 54 28
# To access a cell value from the first row, second column: concepts[1, 2]
# concepts[1, 2]
# concepts[1:2, 1:3]

# If you want to change/modify/amend/supplement the reference file provision for the user
# Look in .csv data file, see if additional columns present, if so, find corresponding reference file?
# This you could do by hand, but not this time round
# Check that the reference file names are still the same!

# list: a generic vector containing other objects
# c: vector
reference_map <- c(
  "domestic" = "budget-type,domestic-budget-level,domestic-sources,currency,fiscal-year"
)
# A bit of recursive definition
reference_map <- c(
  reference_map
  , "domestic-sectors" = "budget-type,domestic-budget-level,domestic-sources,currency,fiscal-year"
)
reference_map <- c(
  reference_map
  , "domestic-netlending" = "budget-type,domestic-budget-level,domestic-sources,currency,fiscal-year"
)
reference_map <- c(
  reference_map
  , "intl-flows-donors" = "flow-type,flow-name"
)
reference_map <- c(
  reference_map
  , "intl-flows-recipients" = "flow-type,flow-name"
)
reference_map <- c(
  reference_map
  , "intl-flows-donors-wide" = "flow-type,flow-name"
)
reference_map <- c(
  reference_map
  , "intl-flows-recipients-wide" = "flow-type,flow-name"
)
reference_map <- c(
  reference_map
  , "largest-intl-flow" = "largest-intl-flow"
)
reference_map <- c(
  reference_map
  , "fragile-states" = "fragile-states"
)
reference_map <- c(
  reference_map
  , "long-term-debt" = "debt-flow,destination-institution-type,creditor-type,creditor-institution,financing-type"
)
reference_map <- c(
  reference_map
  , "oda" = "sector,bundle,channel"
)
reference_map <- c(
  reference_map
  , "oof" = "sector,oof-bundle,channel"
)
reference_map <- c(
  reference_map
  , "fdi-out" = "financing-type"
)
reference_map <- c(
  reference_map
  , "dfis-out-dev" = "financing-type"
)
reference_map <- c(
  reference_map
  , "ssc-out" = "financing-type"
)

# Uganda
reference_map <- c(
  reference_map
  , "uganda-finance" = "uganda-budget-level"
)
#print(reference_map)

# At this point reference_map is a vector
# Get the number of columns
# print(length(reference_map))
# 16
# print(reference_map[1])

###############################################################################

# Main loop

# Iterate through files in the 'country-year' directory and any subdirectories within it
# For each .csv do:
# START FOR EACH DATA FILE LOOP
print("")
print("=============================Beginning of main loop=============================")
print("")

# Test the non use of files in folders that we want to exclude
# for ( i in c( 186, 237, 247, 311, 317, 318 ) ) {

# Test output that you expect to work/ work well
# for ( i in c( 6, 11, 30, 50, 187, 250, 284 ) ) {

# Test output that throws a warning (i.e., government finance data files)
# See: https://github.com/devinit/datahub-angular/issues/96#issuecomment-291841126
# And: https://github.com/devinit/datahub-angular/issues/96#issuecomment-291845394
# for ( i in c( 21, 22, 23, 46, 235, 236 ) ) {

# These are the 'oda-donor' files that are broken!
# for ( i in 50:137 )

# These are the 'warehouse/fact/oda.*.csv' files that are broken!
# for ( i in 268:284 )

# Excluding the oda.*.csv files, code does not work for these
# for ( i in c( 1:267, 285:length( absolute_file_name ) ) ) {

# Random test
for ( i in c( 1:2 ) ) {

# All
# for ( i in 1:length( absolute_file_name ) ) {

  # Show the absolute path for the file that is being processed
  print("")
  print( paste( "Absolute file name:                                    ", absolute_file_name[ i ], sep = "" ) )
  print("")

  # Exclude files from the following sub directories
  # country-year/spotlight-on-kenya/
  # country-year/warehouse/data_series/
  # country-year/warehouse/dimension/
  # country-year/warehouse/donor_profile/
  # country-year/warehouse/recipient_profile/
  # country-year/warehouse/multilateral_profile/
  # country-year/warehouse/south_south_cooperation/

  # START EXCLUDE FOLDERS
  # Test with: 186
  if ( grepl( "/spotlight-on-kenya/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # No test, 'data_series' folder is empty and does not need to be excluded explicitly
  } else if ( grepl( "/warehouse/data_series/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Test with: 237
  } else if ( grepl( "/warehouse/dimension/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Test with: 247
  } else if ( grepl( "/warehouse/donor_profile/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Test with: 311
  } else if ( grepl( "/warehouse/multilateral_profile/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Test with: 317
  } else if ( grepl( "/warehouse/recipient_profile/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Test with: 318
  } else if ( grepl( "/warehouse/south_south_cooperation/", absolute_file_name[ i ] ) ) {
    print("")
    print( paste("Discarding:                                            ", absolute_file_name[ i ], sep = "" ) )
    print("")
  # Use file to created 'user-data' output
  } else {

    # Extract the relative file name from the absolute name
    # This file name is relative to the working directory
    # substr: extracts or replaces substrings in a character vector
    # basename: removes all of the path up to and including the last path separator (if any)
    # This does not work with the new 'concepts.csv' set up because 'id's have "/" in them
    # relative_file_name = substr(
    #   basename( absolute_file_name[ i ] )
    #   , 1
    #   , nchar( basename( absolute_file_name[ i ] ) ) - 4 # Remove .csv from base name
    # )
    #

    # 42 = i after ...country-year/
    # nchar( absolute_file_name[ i ] ) = length of absolute_file_name
    # - 4 = get rid of the '.csv'
    relative_file_name = substr( absolute_file_name[ i ], 42, nchar( absolute_file_name[ i ] ) - 4 )
    print("")
    print( paste( "Relative file name:                                    ", relative_file_name, ".csv", sep = "" ) )
    print("")

    # regexpr(pattern = "/", relative_file_name) = index of /
    # + 1 = first character after the /
    # nchar( relative_file_name ) = length of file_name, also position of last character
    # The relative file name (relative_file_name) may have several '/' in it
    # The tru file names comes after the last instance of '/'
    # So we want to match anything that comes after the last instance of '/'
    file_name = substr( relative_file_name, regexpr( pattern = "[^/]*$", relative_file_name ), nchar( relative_file_name ) )
    print("")
    print( paste( "File name:                                             ", file_name, ".csv", sep = "") )
    print("")

    # Put in a check here to only process files that have an entry in the control file concepts.csv
    # There may be more files in the country-year' directory and any subdirectories within it than in the control file
    # START CHECK IF CONCEPT IN CONTROL IF
    if ( relative_file_name %in% concepts$id ) {

      # Get the data from the .csv file & store them in a data frame
      data <- read.csv(
      absolute_file_name[ i ]
        , header = TRUE
        , sep = ","
        , na.strings = ""
        , check.names = FALSE
      )
      # print(data)
      # print(dim(data))

      # Get the column names from the .csv and store them in a vector
      # colnames: retrieves or sets the row or column names of a matrix-like object
      column_name <- colnames( data )
      # print(column_name)
      # print(length(column_name))

      # Create a file name using the working directory + file name you just extracted
      # You will use this name to label the output folder
      # paste: concatenates vectors after converting to character

      # regexpr(pattern = "/", relative_file_name) = index of /
      # + 1 = first character after the /
      # nchar( relative_file_name ) = length of file_name, also position of last character
      output_folder_name = paste(
        wd
        , file_name
        , sep = "/"
      )
      print("")
      print( paste( "Output folder:                                         ", output_folder_name, "/", sep = "" ) )
      print("")
      # print(output_folder_name)

      # Read in the 'entity.csv', keep only the first ("id") and the last ("name") column
      entity <- read.csv(
        paste( reference_file_location, "entity.csv", sep = "/" )
        , as.is = TRUE
        , na.strings = ""
      )[ c("id", "name") ]
      # print(entity)

      # Spotlight on Uganda
      # Read in the 'uganda-district-entity.csv', keep only the first ("id") and the last ("name") column
      uganda_district <- read.csv(
        paste(reference_file_location, "uganda-district-entity.csv", sep = "/")
        , as.is = TRUE
        , na.strings = ""
      )[ c("id", "name") ]
      # print(uganda_district)

      # Rename the column header in the look up data frames ('entity' & 'uganda_district')
      # names: gets or sets the names of an object
      names( entity ) <- c( "id", "entity-name" )
      names( uganda_district ) <- c( "id", "entity-name" )
      # print(entity)
      # print(uganda_district)

      # Merge two data frames by common columns or row names
      if ( "id" %in% column_name ) {
        data <- merge(
          entity
          , data
          , by = c( "id" ) # Specifications of the columns used for merging
          , all.y = TRUE
          # if 'TRUE', then extra rows will be added to the
          # output, one for each row in 'x' that has no matching row in
          # 'y'.  These rows will have 'NA's in those columns that are
          # usually filled with values from 'y'.  The default is 'FALSE',
          # so that only rows with data from both 'x' and 'y' are
          # included in the output.
        )
      } else {
        if ( "id-to" %in% column_name ) {
          # Rename the 'entity' look up data frame column header
          names( entity ) <- c( "id-to", "entity-to-name" )
          data <- merge(
            entity
            , data
            , by = c( "id-to" )
            , all.y = TRUE
          )
        }
        if ( "id-from" %in% column_name ) {
          # Rename the 'entity' look up data frame column header
          names( entity ) <- c( "id-from", "entity-from-name" )
          data <- merge(
            entity
            , data
            , by = c( "id-from" )
            , all.y = TRUE
          )
        }
      }

      # Special Spotlight on Uganda data case
      if ( substr( relative_file_name, 1, 7 ) == "uganda-" ) {
        # which: gives the 'TRUE' indices of a logical object, allowing for array indices.
        data <- data[ , -which( names( data ) %in% c( "entity-name" ) ) ]
        if ("id" %in% column_name ) {
          data <- merge(
            uganda_district
            , data
            , by = c( "id" )
            , all.y = TRUE
          )
        }
      }

      # Sort the 'data' data frame
      # We've already done this once before? See line xxx above
      # column_name <- colnames( data )
      if ( "entity-name" %in% column_name ) {
        # Sort by year
        if ( "year" %in% column_name ) {
          # order: returns a permutation which rearranges its first argument into
          # ascending or descending order, breaking ties by further arguments.
          data <- data[ order( data[ "entity-name" ], data$year ), ]
        # Sort by entity name
        } else {
          data <- data[ order( data[ "entity-name" ] ), ]
        }
      } else if ( "entity-to-name" %in% column_name ) {
        if ( "year" %in% column_name ) {
          data <- data[ order( data[ "entity-to-name" ], data$year ), ]
        } else {
          data <- data[ order( data[ "entity-to-name" ] ), ]
        }
      } else if ( "entity-from-name" %in% column_name ) {
        if ( "year" %in% column_name ) {
          data <- data[ order( data[ "entity-from-name" ], data$year ), ]
        } else {
          data <- data[ order( data[ "entity-from-name" ] ), ]
        }
      } else if ( "id" %in% column_name ) {
        if ( "year" %in% column_name ) {
          data <- data[ order( data[ "id" ], data$year ), ]
        } else {
          data <- data[ order( data[ "id" ] ), ]
        }
      } else {
        if ( "year" %in% column_name ) {
          data <- data[ data$year, ]
        } else {
          data <- data[ order( data[ , 1 ] ), ]
        }
      }

      # Create a folder for each indicator with a subdirectory called 'csv'
      # Where output_folder_name = paste( wd, relative_file_name, sep = "/" )
      dir.create( output_folder_name )
      setwd( output_folder_name )
      csv_sub_directory = paste( output_folder_name, "csv", sep = "/" )
      print("")
      print( paste( "Output .csv sub directory:                             ", csv_sub_directory, "/", sep = "" ) )
      print("")
      dir.create( csv_sub_directory )

      # Create workbook (the .xlsx file)
      xlsx_file_name = paste( output_folder_name, file_name, sep = "/" )
      xlsx_work_book <- createWorkbook( xlsx_file_name )
      print("")
      # print( paste( ".xlsx file name:                             ", paste( output_folder_name, file_name, sep = "/" ), sep = "" ) )
      print( paste( ".xlsx file name:                                       ", xlsx_file_name, ".xlsx", sep = "" ) )
      print("")

      # Create 'Notes' worksheet (tab)
      # Start notes tab, first tab in .xlsx file
      # c = array
      concept = concepts[ which( concepts$id == relative_file_name ), ]
      notes_for_user <- c(
        paste( "Name:", file_name )
        , paste( "Description:", concept$description )
        , paste( "Units of measure:", concept$uom )
        , paste( "Source:", concept[ , "source" ] )
        # is.na: 'Not Available' / Missing Values
        # , if ( !is.na( concept[ , "source-link" ] ) ) {
        #     c( paste( "Source-link:", concept[ , "source-link"] ), "" )
        #   } else {
        #     ""
        #   }
        # The 'if' statement is not vectorized. For vectorized 'if' statements you should use 'ifelse'
        , ifelse(
          concept[ , "source-link" ]
          , c( paste( "Source-link:", concept[ , "source-link"] ), "" )
          , ""
        )
        , "Notes:"
        # , if ( !is.na( concept[ , "calculation" ] ) ) {
        #     c("", concept[ , "calculation" ], "")
        #   } else {
        #     ""
        #   }
        , ifelse(
          concept[ , "calculation" ]
          , c( "", concept[ , "calculation" ], "" )
          , ""
        )
      )

      # Add a note for the user if the values in the 'value' column have been interpolated
      interpolated <- concept$interpolated[ i ]
      if ( !is.na( interpolated ) ) {
        notes_for_user <- c(
          notes_for_user
          , "This data contains interpolated values. The interpolated values are typically contained in a column called 'value,' while the uninterpolated values are stored in 'original-value.'"
          , ""
        )
      }
      # Add a note for the user if the values in the 'value' column have been estimated
      if ( "estimate" %in% column_name ) {
        notes_for_user <- c(
          notes_for_user
          , "This data contains information that may be a projection. Projected data points are indicated by a value of TRUE in the 'estimate' column. The year at which projections begin varies from country to country."
          , ""
        )
      }
      # Add a note for the user if the values in the 'value' column are NCU values
      if ( "value-ncu" %in% column_name ) {
        notes_for_user <- c(
          notes_for_user
          , "This data contains information that has been converted from current native currency units (NCU) to constant US Dollars. The NCU values are contained in the 'value-ncu' column, while the converted and deflated values are contained in the 'value' column."
          , ""
        )
      }

      # Write 'Notes' data to tab
      addWorksheet(xlsx_work_book, "Notes")
      # ?
      write.csv(
        data
        , paste0( csv_sub_directory, "/", file_name, ".csv" )
        , row.names = FALSE
        , na = ""
      )
      # Add main data tab
      addWorksheet(
        # xlsx_file_name
        xlsx_work_book
        , "Data"
      )
      # Write the main data to file
      writeData(
        xlsx_work_book
        , sheet = "Data"
        , data
        , colNames = TRUE
        , rowNames = FALSE
      )

      # If we have an id, a year to widen it by and it's simple, provide a "wide" file
      # In the "wide" file years are the columns
      # This is the standard Excel format many users are used to
      # If 'type' not simple, no wide file
      # This will not evaluate if the 'type' column in the concepts.csv file is blank!
      # I've modified the 'type' column in the concepts.csv file by setting it = 'undefined' where problematic
      # Watch out for the difference between & (|) and && (||)
      # The shorter version works element wise
      # The longer version uses only the first element of each vector
      # Previously the below 'if' statements were using &, execution was halted
      if ( "id" %in% column_name &&
           "year" %in% column_name &&
           "value" %in% column_name &&
           !is.null( concept$type ) &&
           concept$type == "simple"
          ) {

        print("")
        print( paste( "Wide file ('value') added for:                         ", file_name, ".csv", sep = "" ) )
        print("")

        if ( "entity-name" %in% column_name ) {
          wide_data <- reshape(
            data[ c( "id", "entity-name", "year", "value" ) ]
            , idvar = c( "id", "entity-name" )
            , timevar = "year"
            , direction = "wide"
          )
        } else {
          wide_data <- reshape(
            data[ c("id", "year", "value") ]
            , idvar = c( "id" )
            , timevar = "year"
            , direction = "wide"
          )
        }

        wide_data_names <- names( wide_data )

        for( j in 1:length( wide_data_names ) ) {
          wide_data_name = wide_data_names[ j ]
          # wide_data_name = the name that will be given to the wide data file
          # Indexing starts at 1
          if ( substr( wide_data_name, 1, 5 ) == "value" ) {
            names( wide_data )[ names( wide_data ) == wide_data_name ] <-
            substr( wide_data_name, 7, nchar( wide_data_name ) )
          }
        }

        notes_for_user <- c(
          notes_for_user
          , "On the 'Data-wide-value' sheet, we have provided the indicator in a wide format. The values you see listed there are from the 'value' column."
          , ""
        )
        addWorksheet(
          xlsx_work_book
          , "Data-wide-value"
        )
        writeData(
          xlsx_work_book
          , sheet = "Data-wide-value"
          , wide_data
          , colNames = TRUE
          , rowNames = FALSE
        )
        write.csv(
          wide_data
          , paste( csv_sub_directory, "/", file_name, "-wide-value", ".csv", sep = "" )
          , row.names = FALSE
          , na = ""
        )
      }

      # Provide a "wide" file (years as columns) for 'original-value'
      if ( "id" %in% column_name &&
           "year" %in% column_name &&
           "original-value" %in% column_name &&
           concept$type == "simple"
          ) {

        print("")
        print( paste( "Wide file ('original-value') added for:                ", file_name, ".csv", sep = "" ) )
        print("")

        if ( "entity-name" %in% column_name ) {
          wide_data <- reshape(
            data[ c( "id", "entity-name", "year", "original-value" ) ]
            , idvar = c("id","entity-name")
            , timevar = "year"
            , direction = "wide"
          )
        } else {
          wide_data <- reshape(
            data[ c( "id", "year", "original-value" ) ]
            , idvar = c( "id" )
            , timevar = "year"
            , direction = "wide"
          )
        }

        wide_data_names <- names( wide_data )

        for( j in 1:length( wide_data_names ) ) {

          wide_data_name = wide_data_names[ j ]

          if ( substr( wide_data_name, 1, 14 ) == "original-value" ) {
            names( wide_data )[ names( wide_data ) == wide_data_name ] <-
            substr( wide_data_name, 16, nchar( wide_data_name ) )
          }
        }

        notes_for_user <- c(
          notes_for_user
          ,"On the 'Data-wide-original-value' sheet, we have provided the indicator in a wide format. The values you see listed there are from the 'original-value' column."
          ,""
        )

        addWorksheet(
          xlsx_work_book
          ,"Data-wide-original-value"
        )
        writeData(
          xlsx_work_book
          , sheet = "Data-wide-original-value"
          , wide_data
          , colNames = TRUE
          , rowNames = FALSE
        )
        write.csv(
          wide_data
          , paste( csv_sub_directory, "/", file_name, "-wide-original-value", ".csv", sep = "" )
          , row.names = FALSE
          , na = ""
        )
      }

      # Add reference files/data
      file.copy(
        paste( reference_file_location, "entity.csv", sep = "" )
        , paste( csv_sub_directory, "entity.csv", sep = "/" )
      )
      if ( relative_file_name %in% names( reference_map ) ) {

        reference_files = strsplit( reference_map[[ relative_file_name ]], "," )[[ 1 ]]

        notes_for_user <- c(
          notes_for_user
          , "The following tabs have been included for reference purposes:"
          , paste( reference_files, collapse = ", " )
          , ""
        )
        for ( j in 1:length( reference_files ) ) {

          # Work out the file name
          reference_file_name = reference_files[ j ]
          reference_relative_file_name = paste( reference_file_location, reference_file_name, ".csv", sep = "" )

          # Copy the reference file
          file.copy(
            reference_relative_file_name
            , paste( csv_sub_directory, "/", reference_file_name, ".csv", sep = "" )
          )
          # ?
          reference_data <- read.csv(
            reference_relative_file_name
            , as.is = TRUE
            , na.strings = ""
          )
          # ?
          addWorksheet( xlsx_work_book, reference_file_name )
          # ?
          writeData(
            xlsx_work_book
            , sheet = reference_file_name
            , reference_data
            , colNames = TRUE
            , rowNames = FALSE
          )
        }
      }

      # Cap off 'Notes' tab
      notes_for_user <- c(
        notes_for_user
        , ""
        , ""
        , "The following is data downloaded from Development Initiative's Datahub: http://data.devinit.org."
        , "It is licensed under a Creative Commons Attribution 4.0 International license."
        , "More information on licensing is available here: https://creativecommons.org/licenses/by/4.0/."
        , "For concerns, questions, or corrections: please email info@devinit.org."
        , "If you experience any technical issues when opening the .xlsx and/or the .csv and/or the .zip files please contact info@devinit.org."
        , "Copyright Development Initiatives Poverty Research Ltd. 2017."
      )
      # ?
      notes_data_frame <- data.frame( notes_for_user )
      # ?
      writeData(
        xlsx_work_book
        , sheet = "Notes"
        , notes_data_frame
        , colNames = FALSE
        , rowNames = FALSE
      )
      # ?
      write.table(
        notes_data_frame
        , paste0( csv_sub_directory, "/", file_name, "-notes", ".csv" )
        , col.names = FALSE
        , row.names = FALSE
        , na = ""
        , sep = ","
      )
      # ?
      saveWorkbook(
        xlsx_work_book
        , paste0( file_name, ".xlsx" )
        , overwrite = TRUE
      )

      # Go back to 'user-data' folder
      setwd(wd)

      print("")
      print( paste( "Working directory: ", wd, sep = "" ) )
      print("")

      # Zip up!

    } else {

      # If we have a file in the 'country-year' folder but no entry in concepts.csv, ignore!
      print(
        paste(
          "Omitting file, no corresponding entry in concepts.csv: "
          , relative_file_name
          , ".csv"
          , sep = "" )
      )

    } # END CHECK IF CONCEPT IN CONTROL IF LOOP

  } # END EXCLUDE FOLDERS IF LOOP

} # END FOR EACH DATA FILE LOOP
print("")
print("================================End of main loop================================")
print("")

# Stopped here
# What's below does not work
# Move zipping up of files to CHECK IF CONCEPT IN CONTROL IF LOOP

# # # Zip the files up
# # cat("\n\nZipping the files up\n\n")
#
# print("")
# print( "Zipping the files up!" )
# print("")
#
# file_name <- list.files(
#   wd
#   , pattern = "/*"
#   , full.names = FALSE
# )
#
# # Excluding the oda.*.csv files, code does not work for these
# for ( i in c( 1:267, 285:length( absolute_file_name ) ) ) {
# # for ( i in c( 1:2 ) ) {
# # # for ( i in 1:length( absolute_file_name ) ) {
# # # for ( i in c( 268:269, 284 ) ) {
# # for ( i in c( 1, 283:284 ) ) {
#
#   # print( substr( file_name[ i ], 0, nchar( file_name[ i ] ) - 0 ) )
#
#   if ( file_name[ i ] %in% concepts$id ) {
#
#     print("")
#     print( paste("Zipping up file: ", file_name[ i ], ".csv", sep = "" ) )
#     print("")
#
#   } else {
#
#     print("")
#     print(
#       paste(
#         "Omitting file, no corresponding entry in concepts.csv: "
#         , file_name
#         , ".csv"
#         , sep = "" )
#     )
#     print("")
#
#   }
#
#   # output_files <- dir(
#   #   wd
#   #   # , file_name[ i ]
#   #   , pattern = "/*"
#   #   , full.names = TRUE
#   # )
#   #
#   # print("")
#   # print( output_files[ i ] )
#   # print("")
#
#   zip( zipfile = file_name[ i ], files = file_name[ i ] )
#   # zip( zipfile = file_name[ i ], files = output_files[ i ] )
#
#   print("================================================================================")
#
# }

print("")
print( "END" )
print("")
