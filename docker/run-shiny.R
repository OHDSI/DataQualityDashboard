#!/usr/bin/env Rscript

library("DataQualityDashboard")

filename = file.path(getwd(), "results.json")
DataQualityDashboard::viewDqDashboard(jsonPath = filename, port=7769, host="0.0.0.0")
