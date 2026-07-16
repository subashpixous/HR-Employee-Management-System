# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 — build the Spring Boot fat jar (Maven + JDK 17)
# ============================================================
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build

# Resolve dependencies first for better layer caching.
COPY pom.xml ./
RUN mvn -B -q dependency:go-offline

# Compile + package (tests skipped in the image build; run them in CI).
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ============================================================
# Stage 2 — slim runtime (JRE only)
# ============================================================
FROM eclipse-temurin:17-jre-jammy AS runtime
WORKDIR /app

# curl is used by the container HEALTHCHECK; also create a non-root user.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -r app && useradd -r -g app app \
 && mkdir -p /app/storage && chown -R app:app /app

COPY --from=build /build/target/*.jar app.jar
RUN chown app:app app.jar

USER app

# Defaults; every value can be overridden by docker-compose / .env.
ENV SERVER_PORT=7060 \
    STORAGE_PATH=/app/storage \
    JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

EXPOSE 7060

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
