install.packages('Rserve', repos = 'http://cran.r-project.org')

library(Rserve)

# Start Rserve,
# Defaults
# host = 127.0.0.1
# port = 6311
Rserve(args="--no-save")