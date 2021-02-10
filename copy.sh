#!/bin/bash

cd ./inst/shinyApps/www

mkdir -p ../../../src/main/resources/static

find ./ -type f ! -name "result*.json" -exec cp --parents -r -t ../../../src/main/resources/static "{}" \+
