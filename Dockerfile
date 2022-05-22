FROM adoptopenjdk/openjdk8:alpine-slim
EXPOSE 8080
RUN addgroup -S pipeline && adduser -S k8s-pipeline -G pipeline
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar
USER k8s-pipeline
ENTRYPOINT ["java","-jar","/app.jar"]