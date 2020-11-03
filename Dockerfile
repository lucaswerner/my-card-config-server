FROM alpine:latest as build

WORKDIR /jvm
RUN apk add openjdk11-jdk
RUN apk add openjdk11-jmods
RUN /usr/lib/jvm/java-11-openjdk/bin/jlink --add-modules java.base,java.compiler,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.smartcardio,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.aot --output openjdk-11-jre

WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
RUN chmod +x ./mvnw
RUN ./mvnw dependency:go-offline -B
COPY src src
RUN ./mvnw package -DskipTests

FROM alpine:latest as production
ARG DEPENDENCY=/app/target

WORKDIR /

RUN mkdir -p /usr/lib/jvm
RUN mkdir -p /app
COPY --from=build /jvm/openjdk-11-jre /usr/lib/jvm/openjdk-11-jre
COPY --from=build ${DEPENDENCY}/config-server-0.0.1.jar /app/config-server-0.0.1.jar

ENV JAVA_HOME=/usr/lib/jvm/openjdk-11-jre
ENV PATH=$PATH:$JAVA_HOME/bin

# Run the Spring boot application
ENTRYPOINT ["java", "-jar -Xms512m -Xmx512m", "/app/config-server-0.0.1.jar"]
