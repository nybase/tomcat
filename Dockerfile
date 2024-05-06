FROM alpine:3.19

ENV TZ=Asia/Shanghai LANG=en_US.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/tomcat CATALINA_BASE=/app/tomcat TOMCAT_MAJOR=9 
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin 


ENV XMX_OPTS=" -XX:InitialRAMPercentage=75.0 -XX:MaxRAMPercentage=75.0 "

ENV SW_AGENT_COLLECTOR_BACKEND_SERVICES=127.0.0.1:11800
#ENV JMX_EXPT=5556 JMX_PORT=5555
#ENV JAVA_AGENT_PROMETHEUS_OPTS=" -javaagent:/app/jmx/jmx_prometheus_javaagent.jar=${JMX_EXPT}:/app/jmx/config.yaml"
#ENV JAVA_AGENT_SKYWALKING_OPTS=" -javaagent:/app/skywalking/skywalking-agent.jar"
ENV JAVA_TOOL_OPTIONS="${JAVA_OPTS} ${JAVA_EXT_OPTS} ${XMX_OPTS} ${JAVA_AGENT_OPTS} ${JAVA_AGENT_SKYWALKING_OPTS}"


# ENV JAVA_TOOL_OPTIONS=" -javaagent:/app/skywalking/skywalking-agent.jar -javaagent:/app/jmx/jmx_prometheus_javaagent.jar=5556:/app/jmx/config.yaml \
#       -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=5555 -Dcom.sun.management.jmxremote.rmi.port=5555 \
#       -Dcom.sun.management.jmxremote.host=0.0.0.0 -Djava.rmi.server.hostname=0.0.0.0 -Dcom.sun.management.jmxremote.authenticate=false \
#       -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "

#  SW_AGENT_COLLECTOR_BACKEND_SERVICES

# https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar
# https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/prometheus/jmx/jmx_prometheus_javaagent/0.17.2/jmx_prometheus_javaagent-0.17.2.jar

# yum only: yum-utils createrepo crontabs curl-minimal dejavu-sans-fonts iproute java-11-openjdk-devel java-21-openjdk-devel telnet traceroute pcre-devel pcre2-devel 
# alpine: openjdk8 openjdk11-jdk openjdk21-jdk vim font-noto-cjk consul openssl1.1-compat
RUN set -eux; addgroup -g 8080 app ; adduser -u 8080 -S -G app -s /bin/bash app ;\
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.cloud.tencent.com/g' /etc/apk/repositories ;\
    apk add --no-cache bash busybox-extras ca-certificates curl wget ;\
    echo -e 'export PATH=$JAVA_HOME/bin:$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH\nexport JMX_PORT=${JMX_PORT:-"5555"}\nexport JMX_EXPT=${JMX_EXPT:-"5556"}' | tee  /etc/profile.d/91-env.sh ;\
    echo -e "export IPV4=\$(ip route get 8.8.8.8 | grep src | awk '{print \$7}')" | tee -a /etc/profile.d/91-env.sh ;\
    echo -e 'export JMX_HOST1=${IPV4}' | tee -a /etc/profile.d/91-env.sh ;\
    echo -e 'export JMX_OPTS1=" -Dcom.sun.management.jmxremote.port=${JMX_PORT} -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}  \
        -Djava.rmi.server.hostname=${JMX_HOST} -Dcom.sun.management.jmxremote.host=${JMX_HOST} \
        -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false " '\
        | tee -a /etc/profile.d/91-env.sh ;\
    echo -e 'export JAVA_OPTS="${JAVA_OPTS} ${JAVA_EXT_OPTS} ${XMX_OPTS} ${JAVA_AGENT_OPTS} ${JAVA_AGENT_SKYWALKING_OPTS}" '| tee -a /etc/profile.d/91-env.sh ;\
    apk add --no-cache bash busybox-extras ca-certificates curl wget iproute2 runit dumb-init tini gnupg libcap openssl su-exec iputils inetutils-ftp jq libc6-compat iptables tzdata \
        procps  iputils  wget tzdata less   unzip  tcpdump  net-tools socat jq mtr psmisc logrotate  tomcat-native \
        runit pcre-dev pcre2-dev openssh-client-default  luajit luarocks iperf3 wrk atop htop iftop tmux jemalloc-dev \
        openjdk8 openjdk21-jdk vim ffmpeg ffmpeg-libs ;\
        TOMCAT_VER=`wget -q https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/ -O - | grep -v M|grep v${TOMCAT_MAJOR}|tail -1|awk '{split($0,c,"<a") ; split(c[2],d,"/") ;split(d[1],e,"v") ; print e[2]}'` ;\
    ln -s /usr/lib/jvm/java-1.8-openjdk /usr/lib/jvm/temurin-8-jdk || true; ln -s /usr/lib/jvm/java-21-openjdk /usr/lib/jvm/temurin-21-jdk || true ; \
    mkdir -p /usr/java; ln -s /usr/lib/jvm/java-1.8-openjdk /usr/java/jvm/jdk1.8 || true; ln -s /usr/lib/jvm/java-21-openjdk /usr/java/jdk-21 || true ; \
    echo $TOMCAT_VER;wget -q -c https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    echo "app"> /etc/cron.allow  ;\
    mkdir -p /logs /usr/local/tomcat /app/tomcat/conf /app/tomcat/logs /app/tomcat/work /app/tomcat/bin /app/tomcat/lib/org/apache/catalina/util /app/lib /app/tmp /app/bin /app/war /app/jmx /app/skywalking  /app/otel ; \
    tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/tomcat --strip-components 1 ;\
    cp -rv /usr/local/tomcat/conf/* /app/tomcat/conf/ ;\
    rm -rf /usr/local/tomcat/webapps/* /app/tomcat/conf/context.xml || true;\
    sed -i -e 's@webapps@/app/war@g' -e 's@SHUTDOWN@UP_8001@g' /app/tomcat/conf/server.xml ;\
    sed -i -e 's/maxParameterCount="1000"$/maxParameterCount="1000" maxHttpHeaderSize="65536"  maxConnections="16384" \n maxThreads="1500" minSpareThreads="25" \
    maxSpareThreads="75"  acceptCount="1500" \n keepAliveTimeout="30000" enableLookups="false"  disableUploadTimeout="true"/g'  /app/tomcat/conf/server.xml;\
    echo -e "server.info=WAF\nserver.number=\nserver.built=\n" | tee /app/tomcat/lib/org/apache/catalina/util/ServerInfo.properties ;\
    echo "<tomcat-users/>" | tee  /app/tomcat/conf/tomcat-users.xml ;\
    SKYWALKING_AGENT_VER=`wget -q http://mirrors.cloud.tencent.com/apache/skywalking/java-agent/ -O - |grep 'href'|tail -1 | awk '{split($2,c,">") ; split(c[2],d,"/<") ; print d[1]}'` ;\
    echo $SKYWALKING_AGENT_VER;wget -q -c http://mirrors.cloud.tencent.com/apache/skywalking/java-agent/$SKYWALKING_AGENT_VER/apache-skywalking-java-agent-$SKYWALKING_AGENT_VER.tgz  -P /tmp;\
    tar zxf /tmp/apache-skywalking-java-agent-$SKYWALKING_AGENT_VER.tgz -C /app/skywalking --strip-components 1 ;\
    JMX_EXPORTER_VER=`wget -q https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/prometheus/jmx/jmx_prometheus_javaagent/maven-metadata.xml -O -|grep '<version>'| tail -1 | awk '{split($1,c,">") ; split(c[2],d,"<") ; print d[1]}'` ;\
    echo $JMX_EXPORTER_VER;wget -q -c https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VER}/jmx_prometheus_javaagent-${JMX_EXPORTER_VER}.jar -O /app/jmx/jmx_prometheus_javaagent.jar; \
    echo -e 'rules:\n- pattern: ".*"\n' > /app/jmx/config.yaml ;\
    OTEL_VER=$(wget -q https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/opentelemetry/javaagent/opentelemetry-javaagent/maven-metadata.xml -O -|grep '<version>'|grep -v -i SNAPSHOT| tail -1 | awk '{split($1,c,">") ; split(c[2],d,"<") ; print d[1]}') ;\
    echo $OTEL_VER;wget -q -c https://mirrors.cloud.tencent.com/nexus/repository/maven-public/io/opentelemetry/javaagent/opentelemetry-javaagent/${OTEL_VER}/opentelemetry-javaagent-${OTEL_VER}.jar -O /app/otel/opentelemetry-javaagent.jar; \
    echo "set mouse-=a" >> ~/.vimrc ;  echo "set mouse-=a" >> /home/app/.vimrc ;\
    chown app:app -R /usr/local/tomcat /app /logs /home/app/.vimrc ; 
    

WORKDIR /app/war

EXPOSE 8080
USER   8080

CMD ["catalina.sh", "run"]




#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.WarLauncher"]
#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.JarLauncher"]

# docker build -f Dockerfile.jdk-apline  -t nybase/jdk:apline-amd64 . &&  docker push nybase/jdk:apline-amd64

# docker build -f Dockerfile.jdk-apline  -t nybase/jdk:apline-arm64 . &&  docker push nybase/jdk:apline-arm64

# docker run -ti  -e SW_AGENT_COLLECTOR_BACKEND_SERVICES=skywalking:11800 -e JAVA_OPTS="-javaagent:/app/skywalking/skywalking-agent.jar" nybase/jdk:apline-amd64 bash
