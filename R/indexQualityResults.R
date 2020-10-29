# @file indexQualityResults.R
#
# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of DataQualityDashboard
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Index
#'
#' @param inputFolder       Location of all DataQualityDashboard result folders
#' @param outputFolder      Location to store index and result files
#'
#' @export
indexQualityResults <-
  function(inputFolder, outputFolder = "output/index", outputFile = "index.json") {
    dir.create(file.path(outputFolder), showWarnings = FALSE)
    result_index <<- data.frame()
    
    addResultsToIndex <- function(json, filename) {
      cdm_source_name <- json$Metadata[[1]]$CDM_SOURCE_NAME
      cdm_source_abbreviation <-
        json$Metadata[[1]]$CDM_SOURCE_ABBREVIATION
      cdm_release_date <- json$Metadata[[1]]$CDM_RELEASE_DATE
      percent_passed <- json$Overview$percentPassed
      end_timestamp <- json$endTimestamp
      
      if (!is.null(cdm_source_name)) {
        
      } else {
        writeLines(paste(filename, "is missing cdm_source_name"))
      }
      result_index <<-
        rbind(
          result_index,
          c(
            cdm_source_name,
            cdm_source_abbreviation,
            percent_passed,
            cdm_release_date,
            end_timestamp,
            filename
          )
        )
    }
    
    directories <- list.dirs(inputFolder, full.names = T, recursive = F)
    directories <- directories[!directories %in% file.path(outputFolder)]
    
    for (d in directories) {
      result_files <-
        list.files(path = d,
                   full.names = T,
                   pattern = "json")
      for (f in result_files) {
        writeLines(paste("processing", f))
        file_contents <- readLines(f, warn = FALSE)
        file_contents_converted <- iconv(file_contents, 'utf-8', 'utf-8', sub = '')
        result_json <- rjson::fromJSON(file_contents_converted,simplify=T)

        #generate unique file name for cdm source execution
        cdm_source_abbreviation <- result_json$Metadata[[1]]$CDM_SOURCE_ABBREVIATION
        cdm_source_abbreviation <- tolower(gsub(" ", "_", cdm_source_abbreviation))
        end_timestamp <- result_json$endTimestamp 
        end_timestamp <- gsub("-","",end_timestamp)
        end_timestamp <- gsub(" ","_",end_timestamp)
        end_timestamp <- gsub(":","",end_timestamp)
        result_filename <- paste0(end_timestamp,"_",cdm_source_abbreviation, ".json")
        
        # copy the result file to the output directory with the index file
        json_string <- rjson::toJSON(result_json)
        write(json_string, file = file.path(outputFolder, result_filename))                
        addResultsToIndex(result_json, result_filename)        
      }
    }
    
    colnames(result_index) <-
      c(
        "cdm_source_name",
        "cdm_source_abbreviation",
        "percent_passed",
        "cdm_release_date",
        "end_timestamp",
        "result_file_name"
      )
    result_index$cdm_release_date <-
      as.Date(result_index$cdm_release_date,
              tryFormats = c("%Y-%m-%d", "%m/%d/%Y"))
    result_index$end_timestamp <-
      as.Date(result_index$end_timestamp)
    result_index$percent_passed <-
      as.numeric(result_index$percent_passed)
    result_index$cdm_source_name <- result_index$cdm_source_name
    
    write(jsonlite::toJSON(result_index), file = file.path(outputFolder, outputFile))
  }
