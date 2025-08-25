# Copyright 2025 Observational Health Data Sciences and Informatics
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

.readThresholdFile <- function(checkThresholdLoc, defaultLoc) {
  thresholdFile <- checkThresholdLoc

  if (checkThresholdLoc == "default") {
    thresholdFile <- system.file(
      "csv",
      defaultLoc,
      package = "DataQualityDashboard"
    )
  }

  colspec <- readr::spec_csv(thresholdFile)

  # plausibleUnitConceptIds is a comma-separated list of concept ids, but it is being interpreted as col_double()
  if ("plausibleUnitConceptIds" %in% names(colspec$cols)) {
    colspec$cols$plausibleUnitConceptIds <- readr::col_character()
  }

  result <- read_csv(
    file = thresholdFile,
    col_types = colspec,
    na = c(" ", "")
  )
  result <- as.data.frame(result)
  return(result)
}
