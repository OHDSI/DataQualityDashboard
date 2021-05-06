source("edit_thresholds_aux.R")
library(dplyr)

setwd("your/own/dir/xx")
file <- file.path(getwd(), "DQD_Field_Level_v5.3.1.txt")
df <- read.csv(file, colClasses = "character", stringsAsFactors = FALSE)

# 1) get longer table
df_long <- pivot_longer_func(file)
write.csv(df_long, file.path(getwd(), "dflong.csv"))

# 2) Edit thresholds, in 'df_long' directly or in excel file 'dflong.csv'
# using the indexes selected using file_thresholds & printed here:
# (be aware that the excel file might have one extra row for column names, see the index in the first column!!)
file_thresholds <- "thresholds_to_add.csv"
print_threshold_location(df_long, file_thresholds)

# 3) get originally wide table!
# (after editing thresholds, ofc)
file_edited = "dflong.csv"
df_new <- pivot_wider_func(file=file_edited)
df_new <- df_new[colnames(df)]

# 4) save it!
file_new <- file.path(getwd(), "DQD_Field_Level_v5.3.1_new.csv")
write.csv(df_new, file_new, row.names = FALSE)

# 5) (Optional) See differences in original / new file 
df.old <- read.csv(file, colClasses = "character", stringsAsFactors = FALSE)
df.new <- read.csv(file_new, colClasses = "character", stringsAsFactors = FALSE)
base::all.equal(df.old, df.new)
