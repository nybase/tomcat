# tomcat
docker image for tomcat

## how to build
```
docker build . -t jdk:x86-20230812

docker buildx build --platform linux/amd64,linux/arm64 -t nybase/jdk:202308 --push .
```

## how to use
deploy your war in /app/war

```
docker run -d  -p 8080:8080 tomcat

curl -v 127.0.0.1:8080
```
