FROM maven:3-amazoncorretto-8 as build
COPY src /home/app/src
COPY pom.xml /home/app/
RUN mvn -f /home/app/pom.xml clean install


FROM openjdk:8u92-jdk-alpine
COPY --from=build  /home/app/target/spring-boot-hello-world-example-0.0.1-SNAPSHOT.jar  /usr/local/lib/demo.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/usr/local/lib/demo.jar"]

