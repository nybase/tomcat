FROM apache/skywalking-java-agent:8.11.0-alpine as skywalking

FROM bitnami/jmx-exporter:latest as jmx-exporter

FROM library/consul:latest as consul

FROM hashicorp/consul-template:latest as consul-template

FROM nybase/kylin:v10

ENV TZ=Asia/Shanghai LANG=C.UTF-8 UMASK=0022 CATALINA_HOME=/usr/local/apache-tomcat CATALINA_BASE=/app/tomcat 
ENV PATH=$CATALINA_HOME/bin:/usr/java/latest/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --from=consul  /bin/consul          /usr/local/bin/

COPY --from=consul-template  /bin/consul-template          /usr/local/bin/

COPY --from=skywalking  /skywalking/agent/          /app/skywalking/

COPY --from=jmx-exporter /opt/bitnami/jmx-exporter/ /app/jmx-exporter/

# yum only: yum-utils createrepo crontabs curl-minimal dejavu-sans-fonts iproute java-11-openjdk-devel java-17-openjdk-devel telnet traceroute pcre-devel pcre2-devel 
# alpine: openjdk8 openjdk11-jdk openjdk17-jdk font-noto-cjk consul vim

RUN set -eux; useradd -u 8080 -o -s /bin/bash app || true ;\
    echo -e 'export PATH=$JAVA_HOME/bin:$PATH\n' | tee /etc/profile.d/91-env.sh ;\
    echo  -e "[temurin]\nname=temurin\nenabled=1\ngpgcheck=0\nbaseurl=https://mirrors.nju.edu.cn/adoptium/rpm/centos8-$(uname -m)\ngpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public" > /etc/yum.repos.d/temurin.repo; \
    echo  -e "[epel]\nname=epel\nenabled=1\ngpgcheck=0\nbaseurl=https://mirrors.nju.edu.cn/epel/8/Everything/$(uname -m)\ngpgkey=https://mirrors.nju.edu.cn/epel/RPM-GPG-KEY-EPEL-8" > /etc/yum.repos.d/epel.repo; \
    yum install -y bash ca-certificates curl wget    openssl sudo iproute iputils net-tools iptables tzdata \
        procps   wget tzdata less   unzip  tcpdump   socat jq mtr psmisc logrotate   \
        pcre-devel pcre2-devel  openssh-clients luajit luarocks iperf3 atop htop iftop \
        temurin-8-jdk  vim \
        tomcat-native fio ;\
    TOMCAT_VER=`wget -q https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/ -O -|grep -v M| grep v8 |tail -1| awk '{split($5,c,">v") ; split(c[2],d,"/") ; print d[1]}'` ;\
    echo $TOMCAT_VER; wget -c https://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz -P /tmp ;\
    mkdir -p /logs /usr/local/apache-tomcat /app/war /app/tomcat/conf /app/tomcat/logs /app/tomcat/work /app/tomcat/bin ; tar zxf /tmp/apache-tomcat-${TOMCAT_VER}.tar.gz -C /usr/local/apache-tomcat --strip-components 1 ;\
    rm -rf /usr/local/apache-tomcat/webapps/* || true;\ 
    cp -rv /usr/local/apache-tomcat/conf/server.xml /app/tomcat/conf/ ;\
    sed -i -e 's@webapps@/app/war@g' -e 's@SHUTDOWN@_SHUTUP_8080@g' /app/tomcat/conf/server.xml ;\
    mkdir -p /app/jar/conf /app/jar/lib /app/jar/tmp  /app/jar/bin ;\
    chown app:app -R /usr/local/apache-tomcat /app /logs;

EXPOSE 8080
USER   8080
CMD ["catalina.sh", "run"]

#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.WarLauncher"]
#CMD ["java","-cp /app/jar/conf/*;/app/jar/lib/*","org.springframework.boot.loader.JarLauncher"]
