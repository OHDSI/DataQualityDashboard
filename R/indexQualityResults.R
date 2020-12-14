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
      cdm_source_abbreviation <- json$Metadata[[1]]$CDM_SOURCE_ABBREVIATION
      cdm_release_date <- format(lubridate::ymd(json$Metadata[[1]]$CDM_RELEASE_DATE),"%Y-%m-%d")
      percent_passed <- json$Overview$percentPassed
      count_passed <- json$Overview$countPassed
      count_failed <- json$Overview$countOverallFailed
      dqd_execution_date <- format(lubridate::ymd_hms(json$endTimestamp),"%Y-%m-%d")
      
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
            count_passed,
            count_failed,
            percent_passed,
            cdm_release_date,
            dqd_execution_date,
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
        result_filename <- paste0(cdm_source_abbreviation, "_dqd_result_", end_timestamp, ".json")
        
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
        "count_passed",
        "count_failed",
        "percent_passed",
        "cdm_release_date",
        "dqd_execution_date",
        "result_file_name"
      )
    result_index$percent_passed <- as.numeric(result_index$percent_passed)
    result_index$count_passed <- as.numeric(result_index$count_passed)
    result_index$count_failed <- as.numeric(result_index$count_failed)
    write(jsonlite::toJSON(result_index), file = file.path(outputFolder, outputFile))
  }
