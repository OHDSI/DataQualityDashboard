FROM r-base:4.1.3

RUN apt-get update \
    && apt-get install -y apt-utils
RUN apt-get update \
    && apt-get install -y default-jdk
RUN apt-get update \
    && apt-get install -y libxml2-dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && export ROOTPASS=$(head -c 12 /dev/urandom |base64 -) && echo "root:$ROOTPASS" | chpasswd

COPY sshd_config /etc/ssh/

RUN R -e "install.packages('DatabaseConnector')"
RUN R -e "install.packages('SqlRender')"
RUN R -e "install.packages('ParallelLogger')"
RUN R -e "install.packages('devtools')"
RUN R -e "remotes::install_github('OHDSI/DataQualityDashboard')"
RUN R -e "install.packages('Rserve',, 'http://rforge.net/', type='source')"
RUN R -e "install.packages('magrittr')"
RUN R -e "install.packages('dplyr')"

VOLUME /rserve

WORKDIR .

COPY dqd-database-manager.R root/R/dqd-database-manager.R
COPY data-quality-check.R root/R/data-quality-check.R
COPY download-jdbc-drivers.R root/R/download-jdbc-drivers.R
COPY log-appender.R root/R/log-appender.R
COPY test-connection.R root/R/test-connection.R
COPY getCheckId.R root/R/getCheckId.R
COPY recordResult.R root/R/recordResult.R
COPY processCheck.R root/R/processCheck.R
COPY executeDqChecks.R root/R/executeDqChecks.R
COPY runCheck.R root/R/runCheck.R
COPY evaluateThresholds.R root/R/evaluateThresholds.R
COPY summarizeResults.R root/R/summarizeResults.R
COPY writeJsonResultsTo.R root/R/writeJsonResultsTo.R
COPY writeResultsTo.R root/R/writeResultsTo.R
COPY readThresholdFile.R root/R/readThresholdFile.R

# Enable tls 1.0, 1.1
COPY java-secure java-secure
RUN tr -d '\015' <./java-secure >./java-secure.tmp && mv ./java-secure.tmp ./java-secure && chmod 700 ./java-secure
RUN ./java-secure

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

EXPOSE 6311 2222

CMD ["./entrypoint.sh"]
