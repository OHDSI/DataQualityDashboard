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

# Format and check code:
styler::style_pkg()
OhdsiRTools::updateCopyrightYearFolder()
OhdsiRTools::findNonAsciiStringsInFolder()
devtools::spell_check()

# Regenerate roxygen docs:
devtools::document()

# Create manual and vignettes:
unlink("extras/DataQualityDashboard.pdf")
shell("R CMD Rd2pdf ./ --output=extras/DataQualityDashboard.pdf") # PC
system("R CMD Rd2pdf ./ --output=extras/DataQualityDashboard.pdf") # Mac

rmarkdown::render("vignettes/AddNewCheck.Rmd",
                  output_file = "../inst/doc/AddNewCheck.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/AddNewCheck.tex")

rmarkdown::render("vignettes/CheckStatusDefinitions.Rmd",
                  output_file = "../inst/doc/CheckStatusDefinitions.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/CheckStatusDefinitions.tex")

rmarkdown::render("vignettes/DataQualityDashboard.Rmd",
                  output_file = "../inst/doc/DataQualityDashboard.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/DataQualityDashboard.tex")

rmarkdown::render("vignettes/DqdForCohorts.Rmd",
                  output_file = "../inst/doc/DqdForCohorts.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/DqdForCohorts.tex")

rmarkdown::render("vignettes/Thresholds.Rmd",
                  output_file = "../inst/doc/Thresholds.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/Thresholds.tex")

rmarkdown::render("vignettes/SqlOnly.Rmd",
                  output_file = "../inst/doc/SqlOnly.pdf",
                  rmarkdown::pdf_document(latex_engine = "pdflatex",
                                          toc = TRUE,
                                          number_sections = TRUE))
unlink("inst/doc/SqlOnly.tex")

pkgdown::build_site()
OhdsiRTools::fixHadesLogo()
