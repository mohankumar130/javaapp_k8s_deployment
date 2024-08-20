# Os Images
FROM ubuntu:jammy
# Set environment variables
ENV CATALINA_HOME /opt/tomcat/tomcat10
ENV PATH $CATALINA_HOME/bin:$PATH
ENV TOMCAT_VERSION 10.1.28
# Install necessary packages
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    vim \
    curl 
# Download and extract Tomcat to /opt/tomcat
RUN mkdir /opt/tomcat \
    && wget https://dlcdn.apache.org/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /tmp/tomcat.tar.gz \ 
    && tar -xvzf /tmp/tomcat.tar.gz -C /opt/tomcat/ \
    && mv /opt/tomcat/apache-tomcat-10.1.25 /opt/tomcat/tomcat10 \
    && rm -rf /tmp/tomcat.tar.gz
# Ensure catalina.sh is executable
RUN chmod +x /opt/tomcat/tomcat10/bin/catalina.sh
# Add Tomcat users configuration
COPY config_file/tomcat-users.xml /opt/tomcat/tomcat10/conf/
# Add manager and host manger context file
COPY config_file/context.xml /opt/tomcat/tomcat10/webapps/host-manager/META-INF/
COPY config_file/context.xml /opt/tomcat/tomcat10/webapps/manager/META-INF/
# Copy the WAR file from the target directory of your Maven project to the Tomcat webapps directory
COPY target/webapp.war /opt/tomcat/tomcat10/webapps/
# Expose port 8080
EXPOSE 8080
# Start Tomcat
CMD ["/opt/tomcat/tomcat10/bin/catalina.sh", "run"]
