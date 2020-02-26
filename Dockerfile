FROM rocker/tidyverse
# docker build -t data-quality-dashboard .
RUN apt-get update && apt-get install -y default-jdk r-cran-rjava
WORKDIR /code
COPY . /code
RUN Rscript -e "devtools::install_local('.')" && \
    Rscript -e "install.packages('shiny')"
WORKDIR /code/inst/shinyApps/www
EXPOSE 7769
ENTRYPOINT ["/bin/bash", "/code/docker/entrypoint.sh"]
