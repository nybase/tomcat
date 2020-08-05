FROM centos:7

ENV TZ=Asia/Shanghai LANG=C.UTF-8 JAVA_HOME=/usr/java/latest UMASK=0022 CATALINA_HOME=/usr/local/apache-tomcat CATALINA_BASE=/app/tomcat
ENV PATH=/usr/local/apache-tomcat/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# add apache-tomcat-8.5.57.tar.gz  jdk-8u202-linux-x64.tar.gz
ADD *.tar.gz /usr/local/

RUN mkdir -p /usr/java /app/tomcat/{conf,logs,temp,webapps,work} ;\
    ln -s /usr/local/apache-tomcat-* /usr/local/apache-tomcat ;\
    ln -s /usr/local/jdk* /usr/java/latest ;\
    cp -rv /usr/local/apache-tomcat/conf /app/tomcat/ 

EXPOSE 8080
CMD ["catalina.sh", "run"]
