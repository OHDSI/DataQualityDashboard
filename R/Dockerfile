FROM r-base

ARG prop=default

RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libssl-dev
RUN apt-get install -y default-jdk
RUN apt-get install -y libxml2-dev

RUN R -e "install.packages('DatabaseConnector')"
RUN R -e "install.packages('SqlRender')"
RUN R -e "install.packages('ParallelLogger')"
RUN R -e "install.packages('devtools')"
RUN R -e "install.packages('properties')"
RUN R -e "devtools::install_github('OHDSI/DataQualityDashboard')"
RUN R -e "install.packages('Rserve',, 'http://rforge.net/', type='source')"

EXPOSE 6311

VOLUME /rserve

WORKDIR .

RUN mkdir root/R
RUN mkdir root/R/properties

COPY properties/${prop}.properties root/R/properties/default.properties
COPY execution.R root/R/execution.R
COPY dqd-database-manager.R root/R/dqd-database-manager.R
COPY data-quality-check.R root/R/data-quality-check.R

# Enable tls 1.0, 1.1
COPY java-secure java-secure
RUN chmod 700 ./java-secure
RUN ./java-secure

ENTRYPOINT R -e "Rserve::run.Rserve(remote=TRUE)"
