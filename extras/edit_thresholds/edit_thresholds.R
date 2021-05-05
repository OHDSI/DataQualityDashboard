source("edit_thresholds_aux.R")

setwd("your/own/dir/xx")
file <- "~/Documents/Projects/EHDEN_UKBiobank/DQD_thresholds_30Apr21/DQD_Field_Level_v5.3.1_UKB.csv"

# 1) get longer table
df_long <- pivot_longer_func(file)
write.csv(df_long, file.path(getwd(), "dflong.csv"))

# 2) Edit thresholds, in df_long directly or in excel file
# using the following indexes:
# be aware that the excel file might have one extra row for column names, see the index in the first column!!
file_thresholds <- "thresholds_to_add.csv"
print_threshold_location(df_long, file_thresholds)

# 3) get originally wide table!
file_edited = "dflong.csv"
df_new <- pivot_wider_func(file=file_edited)
# 4) save it!

write.csv(df_new, file.path(getwd(), "DQD_Field_Level_v5.3.1_new.csv"))
