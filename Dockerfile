FROM ghcr.io/rocker-org/devcontainer/r-ver:4

# Install Java 25 via SDKMAN (matching devcontainer feature)
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source /root/.sdkman/bin/sdkman-init.sh \
    && sdk install java 25.0.2-ms \
    && sdk default java 25.0.2-ms"

ENV SDKMAN_DIR="/root/.sdkman"
ENV JAVA_HOME="/root/.sdkman/candidates/java/current"
ENV PATH="${JAVA_HOME}/bin:${SDKMAN_DIR}/bin:${PATH}"

# Reconfigure rJava to use the new Java installation
RUN R CMD javareconf

WORKDIR /app

COPY DESCRIPTION NAMESPACE ./
COPY R/ R/
COPY inst/ inst/
COPY man/ man/
COPY extras/ extras/
COPY tests/ tests/
COPY vignettes/ vignettes/

RUN mkdir -p /app/output

RUN Rscript -e "devtools::install_deps(dependencies = TRUE)"

# Install the package from local source
RUN Rscript -e "install.packages('.', repos = NULL, type = 'source')"

# main.r is expected to be mounted in by the user at runtime
# e.g. docker run -v /path/to/main.r:/app/main.r <image>
ENTRYPOINT ["Rscript", "main.r"]
