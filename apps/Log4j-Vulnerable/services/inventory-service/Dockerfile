FROM maven:3.8.4-openjdk-11 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:11-jre
WORKDIR /app
COPY --from=builder /app/target/inventory-service-1.0.0.jar app.jar

VOLUME ["/flags"]

EXPOSE 8002
ENTRYPOINT ["java", "-jar", "app.jar"]