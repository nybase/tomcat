FROM alpine:3.15

ENV TZ=Asia/Shanghai LANG=C.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/apache-tomcat CATALINA_BASE=/app/tomcat JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH=/usr/local/apache-tomcat/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -eux; addgroup -g 8080 app ; adduser -u 8080 -S -G app app ; \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories ;\
    apk add --no-cache bash busybox-extras ca-certificates curl wget iproute2 runit dumb-init gnupg libcap openssl su-exec iputils jq libc6-compat iptables tzdata \
        procps  iputils  wget tzdata less   unzip  tcpdump  net-tools socat jq mtr psmisc logrotate  tomcat-native \
        runit pcre-dev pcre2-dev  openssh-client-default  luajit luarocks iperf3 wrk atop htop iftop \
        openjdk17-jdk consul vim ;\
    mkdir -p /usr/java /app/tomcat/lib/org/apache/catalina/util/ /app/war /logs /app/tomcat/bin /app/tomcat/conf /app/tomcat/logs /app/tomcat/temp /app/tomcat/work ;\
    TOMCAT_VER=`curl --silent http://mirror.vorboss.net/apache/tomcat/tomcat-9/ | grep v9 | awk '{split($5,c,">v") ; split(c[2],d,"/") ; print d[1]}'` ;\
    echo $TOMCAT_VER; wget -Nnv http://mirror.vorboss.net/apache/tomcat/tomcat-9/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    mkdir -p /usr/local/apache-tomcat; tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/apache-tomcat --strip-components 1 ;\
    rm -rf /usr/local/apache-tomcat/webapps/* || true;\ 
    sed -i -e 's+SHUTDOWN+UP!2345+g' -e 's+webapps+/app/war+g' /usr/local/apache-tomcat/conf/server.xml ;\
    echo -e 'server.info=WAF\nserver.number=\nserver.built=\n' | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    cp -rf /usr/local/apache-tomcat/conf/* /app/tomcat/conf/ ;\
    chown app -R /usr/local/apache-tomcat /app/tomcat /app/war /logs ;\
    rm -rf /tmp/* 
    

EXPOSE 8080
USER   8080
CMD ["catalina.sh", "run"]
