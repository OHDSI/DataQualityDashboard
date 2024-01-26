# Read check descriptions into a dataframe
checkDescriptions <- read.csv("inst/csv/OMOP_CDMv5.4_Check_Descriptions.csv")

# Template
templateText <- paste(readLines('extras/checkDescriptionTemplate.Rmd', encoding = 'UTF-8'), collapse = "\n")

checkText <- sprintf(
        templateText, 
        checkDescriptions$checkName,
        checkDescriptions$checkLevel,
        checkDescriptions$kahnContext,
        checkDescriptions$kahnCategory,
        checkDescriptions$kahnSubcategory,
        checkDescriptions$severity,
        checkDescriptions$checkDescription
)

# Write each element of checkText to a file
for (i in seq_along(checkText)) {
    checkName <- checkDescriptions$checkName[i]
    writeLines(
        checkText[i],
        file.path('extras/checks', paste0(checkName, ".Rmd"))
    )
    cat(sprintf("- [%s](%s.html)\n", checkName, checkName))
}
for (checkName in checkDescriptions$checkName) {
    cat(sprintf("      - text: %s\n", checkName))
    cat(sprintf("        href: articles/checks/%s.html\n", checkName))
}
