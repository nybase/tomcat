FROM alpine:latest

ENV TZ=Asia/Shanghai LANG=C.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/apache-tomcat CATALINA_BASE=/app/tomcat JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH=/usr/local/apache-tomcat/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories ;\
    groupadd -o -g 8080 app  &&  useradd -u 8080 --no-log-init -r -m -s /bin/bash -o app ; \
    apk add --no-cache bash busybox-extras ca-certificates curl wget iproute2 runit dumb-init gnupg libcap openssl su-exec iputils jq libc6-compat iptables tzdata \
        procps  iputils  wget tzdata less   unzip  tcpdump  net-tools socat jq mtr psmisc logrotate  tomcat-native \
        runit pcre-dev pcre2-dev  openssh-client-default  luajit luarocks iperf3 wrk atop htop iftop \
        openjdk11-jdk consul vim ;\
    mkdir -p /usr/java /app/tomcat/lib/org/apache/catalina/util/ /app/tomcat/{bin,conf,logs,temp,webapps,work} ;\
    TOMCAT_VER=`curl --silent http://mirror.vorboss.net/apache/tomcat/tomcat-9/ | grep v9 | awk '{split($5,c,">v") ; split(c[2],d,"/") ; print d[1]}'` ;\
    echo $TOMCAT_VER; wget -N http://mirror.vorboss.net/apache/tomcat/tomcat-9/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    mkdir -p /usr/local/apache-tomcat; tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/apache-tomcat --strip-components 1 ;\
    rm -rf /usr/local/apache-tomcat/webapps/* || true;\ 
    sed -i -e 's+SHUTDOWN+UP!2345+g' -e 's+webapps+/app/war+g' /usr/local/apache-tomcat/conf/server.xml
    echo -e 'server.info=WAF\nserver.number=\nserver.built=\n' | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    cp -rf /usr/local/apache-tomcat/conf/* /app/tomcat/conf/ ;\
    

EXPOSE 8080
USER app
CMD ["catalina.sh", "run"]
