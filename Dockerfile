# 1st Build Step
FROM openjdk:17 as build

WORKDIR /workspace/app

# Source
COPY src src
COPY inst/shinyApps/www/css src/main/resources/static/
COPY inst/shinyApps/www/htmlwidgets src/main/resources/static/
COPY inst/shinyApps/www/img src/main/resources/static/
COPY inst/shinyApps/www/js src/main/resources/static/
COPY inst/shinyApps/www/vendor src/main/resources/static/
COPY inst/shinyApps/www/favicon.ico src/main/resources/static/
COPY inst/shinyApps/www/index.html src/main/resources/static/

# Maven
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

RUN tr -d '\015' <./mvnw >./mvnw.sh && mv ./mvnw.sh ./mvnw && chmod 770 mvnw

RUN ./mvnw package

# 2nd Run Step
FROM openjdk:17
VOLUME /tmp

ARG JAR_FILE=/workspace/app/target/*.jar
COPY --from=build ${JAR_FILE} app.jar
ENTRYPOINT ["sh", "-c", "java ${JAVA_OPTS} -jar /app.jar ${0} ${@}"]

