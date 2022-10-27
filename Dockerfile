FROM apache/skywalking-java-agent:8.12.0-alpine as skywalking

#FROM bitnami/jmx-exporter:latest as jmx

FROM alpine:3.16

ENV TZ=Asia/Shanghai LANG=UTF-8.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/tomcat CATALINA_BASE=/app/tomcat TOMCAT_MAJOR=8
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV JAVA_TOOL_OPTIONS=" -javaagent:/app/skywalking/skywalking-agent.jar -javaagent:/app/jmx/jmx_prometheus_javaagent.jar=5556:/app/jmx/config.yaml \
 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=5555 -Dcom.sun.management.jmxremote.authenticate=false \
 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=true -XX:InitialRAMPercentage=60.0 -XX:MaxRAMPercentage=60.0 "

#  SW_AGENT_COLLECTOR_BACKEND_SERVICES

COPY --from=skywalking  /skywalking/agent/          /app/skywalking/

#COPY --from=jmx /opt/bitnami/jmx/ /app/jmx/

# https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar

# yum only: yum-utils createrepo crontabs curl-minimal dejavu-sans-fonts iproute java-11-openjdk-devel java-17-openjdk-devel telnet traceroute pcre-devel pcre2-devel 
# alpine: openjdk8 openjdk11-jdk openjdk17-jdk font-noto-cjk consul vim
RUN set -eux; addgroup -g 8080 app ; adduser -u 8080 -S -G app app ;\
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories ;\
    echo -e 'export PATH=$JAVA_HOME/bin:$PATH\n' | tee /etc/profile.d/91-env.sh ;\
    apk add --no-cache bash busybox-extras ca-certificates curl wget iproute2 runit dumb-init tini gnupg libcap openssl su-exec iputils jq libc6-compat iptables tzdata \
        procps  iputils  wget tzdata less   unzip  tcpdump  net-tools socat jq mtr psmisc logrotate  tomcat-native \
        runit pcre-dev pcre2-dev  openssh-client-default  luajit luarocks iperf3 wrk atop htop iftop \
        openjdk8 openjdk17-jdk consul consul-template vim font-noto-cjk ;\
        TOMCAT_VER=`wget  -q https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/ -O -|grep -v M| grep v${TOMCAT_MAJOR} |tail -1| awk '{split($5,c,">v") ; split(c[2],d,"/") ; print d[1]}'` ;\
    echo $TOMCAT_VER;wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    echo "app"> /etc/cron.allow  ;\
    mkdir -p /logs /usr/local/tomcat /app/war /app/tomcat/conf /app/tomcat/logs /app/tomcat/work /app/tomcat/bin /app/tomcat/lib/org/apache/catalina/util; \
    tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/tomcat --strip-components 1 ;\
    cp -rv /usr/local/tomcat/conf/* /app/tomcat/conf/ ;\
    rm -rf /usr/local/tomcat/webapps/* /app/tomcat/conf/context.xml || true;\ 
    sed -i -e 's@webapps@/app/war@g' -e 's@SHUTDOWN@UP_8001@g' /app/tomcat/conf/server.xml ;\
    echo  "server.info=WAF\nserver.number=\nserver.built=\n" | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    echo "<tomcat-users/>" | tee  /app/tomcat/conf/tomcat-users.xml ;\
    mkdir -p /app/war /app/lib /app/tmp  /app/bin /app/jmx ;\
    JMX_EXPORTER_VER=`wget -q https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/maven-metadata.xml -O -|grep '<version>'| tail -1 | awk '{split($1,c,">") ; split(c[2],d,"<") ; print d[1]}'` ;\
    echo $JMX_EXPORTER_VER;wget -c https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VER}/jmx_prometheus_javaagent-${JMX_EXPORTER_VER}.jar -O /app/jmx/jmx_prometheus_javaagent.jar; \
    echo -e 'rules:\n- pattern: ".*"' > /app/jmx/config.yaml ;\
    echo "set mouse-=a" >> ~/.vimrc ;  echo "set mouse-=a" >> /home/app/.vimrc ;\
    chown app:app -R /usr/local/tomcat /app /logs /home/app/.vimrc ;

WORKDIR /app/war

EXPOSE 8080
USER   8080

CMD ["catalina.sh", "run"]

#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.WarLauncher"]
#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.JarLauncher"]
