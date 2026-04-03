FROM maven:3.8.4-openjdk-8 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM openjdk:8u181-jre-stretch
WORKDIR /app
COPY --from=builder /app/target/auth-service-1.0.0.jar app.jar

# Mount point for flags
VOLUME ["/flags"]

EXPOSE 8001
ENTRYPOINT ["java", "-jar", "app.jar"]
