# Docker Complete Guide

> **Docker Engine + Docker CLI + Docker Compose + Images + Containers +
> Networks + Volumes + Dockerfile + Registry + Buildx + Logs +
> Troubleshooting + Security + Production basics**
>
> Энэ guide нь Linux/Arch хэрэглэгч Docker-ийг шинээр суулгахаас эхлээд
> өдөр тутмын container management, Compose stack, persistent storage,
> networking, image build/push, troubleshooting, cleanup, automation
> хүртэл copy-paste хийхэд зориулсан practical reference юм.
>
> Docker Engine нь `dockerd` daemon, API болон `docker` CLI-аас бүрдэх
> client-server architecture ашигладаг. Docker images, containers,
> networks, volumes зэрэг object-уудыг daemon удирддаг.
> citeturn0search1

------------------------------------------------------------------------

# 0. Docker гэж юу вэ?

Docker бол application-ийг isolated container дотор ажиллуулах platform.

Mental model:

``` text
                         DOCKER
                           |
              +------------+------------+
              |            |            |
            IMAGE       CONTAINER     NETWORK
              |            |            |
              |            |            |
              +------------+------------+
                           |
                         VOLUME
                           |
                      Persistent data
```

Docker architecture:

``` text
Terminal
   |
   | docker CLI
   v
 dockerd
   |
   +-------------------------------+
   |               |               |
   v               v               v
 Images        Containers       Networks
                                   |
                                Volumes
```

Docker Engine-ийн үндсэн component:

``` text
docker CLI
    ↓
Docker API
    ↓
dockerd
    ↓
containerd
    ↓
runc
    ↓
Linux namespaces / cgroups
```

------------------------------------------------------------------------

# 1. Docker vs Incus vs Kubernetes

Эдгээрийг нэг түвшний tool гэж ойлгож болохгүй.

``` text
Physical / VM Host
        |
        v
      Incus
        |
        +-------------------+
        |                   |
       VM              System Container
        |
        v
      Linux
        |
        v
      Docker
        |
        +------------------+
        |                  |
      App A              App B
        |
        v
   Docker Compose
```

Kubernetes нэмбэл:

``` text
Incus
  |
  +-- VM
       |
      Linux
       |
      k3s / Kubernetes
       |
      Pods
       |
   Containers
```

Ерөнхий responsibility:

``` text
Terraform
  → Infrastructure provisioning

Incus
  → VM / system container

Ansible
  → OS / configuration management

Docker
  → Application containers

Docker Compose
  → Multi-container application stack

Kubernetes
  → Container orchestration
```

------------------------------------------------------------------------

# 2. Docker Engine vs Docker Desktop

Linux server / homelab / production server дээр:

``` text
Docker Engine
```

ашиглах нь түгээмэл.

Docker Desktop нь:

``` text
Docker Engine
+ Docker CLI
+ Docker Compose
+ GUI
+ additional developer features
```

зэрэг bundle хэлбэртэй.

Энэ guide нь **Docker Engine on Linux** дээр төвлөрнө.

Official Docker Engine installation documentation:
https://docs.docker.com/engine/install/ citeturn0search0

------------------------------------------------------------------------

# 3. Arch Linux дээр Docker суулгах

Arch дээр:

``` bash
sudo pacman -Syu
sudo pacman -S docker docker-compose
```

Шалгах:

``` bash
docker --version
```

``` bash
docker compose version
```

Service:

``` bash
sudo systemctl enable --now docker
```

Шалгах:

``` bash
systemctl status docker
```

Docker test:

``` bash
sudo docker run hello-world
```

Docker Compose нь Linux дээр Docker Engine/CLI-ийн plugin байдлаар
ашиглагддаг; legacy standalone Compose нь recommended биш.
citeturn0search4

> Arch package naming/version нь тухайн Arch repository snapshot-оос
> хамаарч өөрчлөгдөж болно. `pacman -Ss docker` болон
> `pacman -Qi docker` ашиглан package-аа шалга.

------------------------------------------------------------------------

# 4. Docker permission

Эхэндээ:

``` bash
sudo docker ps
```

гэж ажиллана.

`docker` command-ийг sudo-гүй ажиллуулахын тулд:

``` bash
sudo usermod -aG docker $USER
```

Дараа нь logout/login.

Эсвэл:

``` bash
newgrp docker
```

Шалгах:

``` bash
docker ps
```

> **Security note:** `docker` group-д user нэмэх нь Docker daemon-ийг
> удирдах өндөр эрх өгдөг. Docker daemon root privileges-тэй ажилладаг
> учраас энэ group-ийг root-equivalent access гэж үзэх нь зөв.

------------------------------------------------------------------------

# 5. Docker service

Start:

``` bash
sudo systemctl start docker
```

Stop:

``` bash
sudo systemctl stop docker
```

Restart:

``` bash
sudo systemctl restart docker
```

Enable:

``` bash
sudo systemctl enable docker
```

Disable:

``` bash
sudo systemctl disable docker
```

Status:

``` bash
systemctl status docker
```

Logs:

``` bash
journalctl -u docker
```

Live logs:

``` bash
journalctl -fu docker
```

------------------------------------------------------------------------

# 6. Docker system information

``` bash
docker info
```

Version:

``` bash
docker version
```

Disk usage:

``` bash
docker system df
```

Detailed disk usage:

``` bash
docker system df -v
```

Docker root directory:

``` bash
docker info | grep "Docker Root Dir"
```

Ихэнх Linux installation дээр:

``` text
/var/lib/docker
```

орчимд байна.

------------------------------------------------------------------------

# 7. Images гэж юу вэ?

Image бол container үүсгэх template.

``` text
Image
  |
  +-- filesystem
  +-- binaries
  +-- libraries
  +-- metadata
  +-- entrypoint
  +-- environment defaults
```

Жишээ:

``` text
nginx:latest
mysql:8
redis:latest
alpine:latest
ubuntu:24.04
```

Image өөрөө running process биш.

``` text
Image
   ↓ docker run
Container
```

------------------------------------------------------------------------

# 8. Images list

``` bash
docker images
```

эсвэл:

``` bash
docker image ls
```

All images:

``` bash
docker image ls -a
```

Image ID:

``` bash
docker image ls --no-trunc
```

------------------------------------------------------------------------

# 9. Pull image

``` bash
docker pull nginx
```

Specific tag:

``` bash
docker pull nginx:1.28
```

Alpine:

``` bash
docker pull alpine:latest
```

MySQL:

``` bash
docker pull mysql:8
```

Redis:

``` bash
docker pull redis:latest
```

------------------------------------------------------------------------

# 10. Image inspect

``` bash
docker image inspect nginx
```

Specific field:

``` bash
docker image inspect nginx \
  --format '{{.Config.ExposedPorts}}'
```

Entrypoint:

``` bash
docker image inspect nginx \
  --format '{{.Config.Entrypoint}}'
```

CMD:

``` bash
docker image inspect nginx \
  --format '{{.Config.Cmd}}'
```

------------------------------------------------------------------------

# 11. Image history

``` bash
docker history nginx
```

Detailed:

``` bash
docker history --no-trunc nginx
```

Image layers:

``` text
Dockerfile
    |
    +-- FROM
    +-- RUN
    +-- COPY
    +-- RUN
    |
    v
 Image
    |
    +-- Layer
    +-- Layer
    +-- Layer
```

------------------------------------------------------------------------

# 12. Container үүсгэх

Энгийн:

``` bash
docker run nginx
```

Гэхдээ terminal block хийнэ.

Background:

``` bash
docker run -d nginx
```

Name:

``` bash
docker run -d \
  --name web01 \
  nginx
```

------------------------------------------------------------------------

# 13. Container list

Running:

``` bash
docker ps
```

All:

``` bash
docker ps -a
```

Quiet IDs:

``` bash
docker ps -q
```

Names:

``` bash
docker ps --format '{{.Names}}'
```

------------------------------------------------------------------------

# 14. Container lifecycle

Start:

``` bash
docker start web01
```

Stop:

``` bash
docker stop web01
```

Restart:

``` bash
docker restart web01
```

Kill:

``` bash
docker kill web01
```

Pause:

``` bash
docker pause web01
```

Unpause:

``` bash
docker unpause web01
```

Remove:

``` bash
docker rm web01
```

Force remove:

``` bash
docker rm -f web01
```

------------------------------------------------------------------------

# 15. Container logs

``` bash
docker logs web01
```

Follow:

``` bash
docker logs -f web01
```

Last 100 lines:

``` bash
docker logs --tail 100 web01
```

With timestamp:

``` bash
docker logs -t web01
```

Since:

``` bash
docker logs --since 10m web01
```

------------------------------------------------------------------------

# 16. Container inspect

``` bash
docker inspect web01
```

IP:

``` bash
docker inspect web01 \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Container state:

``` bash
docker inspect web01 \
  --format '{{.State.Status}}'
```

Restart policy:

``` bash
docker inspect web01 \
  --format '{{.HostConfig.RestartPolicy.Name}}'
```

------------------------------------------------------------------------

# 17. Container resource usage

``` bash
docker stats
```

Specific:

``` bash
docker stats web01
```

One-time output:

``` bash
docker stats --no-stream
```

Processes:

``` bash
docker top web01
```

------------------------------------------------------------------------

# 18. Container дотор shell

``` bash
docker exec -it web01 bash
```

Alpine:

``` bash
docker exec -it web01 sh
```

Root shell:

``` bash
docker exec -it web01 /bin/sh
```

Single command:

``` bash
docker exec web01 hostname
```

Multiple:

``` bash
docker exec web01 sh -c 'id && hostname && df -h'
```

------------------------------------------------------------------------

# 19. Container дотор environment

``` bash
docker exec web01 env
```

Inspect:

``` bash
docker inspect web01 \
  --format '{{json .Config.Env}}'
```

------------------------------------------------------------------------

# 20. Port mapping

Container дотор:

``` text
80
```

Host дээр:

``` text
8080
```

бол:

``` bash
docker run -d \
  --name web01 \
  -p 8080:80 \
  nginx
```

Тэгээд:

``` bash
curl http://localhost:8080
```

Port list:

``` bash
docker port web01
```

------------------------------------------------------------------------

# 21. Port syntax

``` text
-p HOST_PORT:CONTAINER_PORT
```

Жишээ:

``` bash
-p 8080:80
```

IPv4 localhost only:

``` bash
-p 127.0.0.1:8080:80
```

Specific host IP:

``` bash
-p 10.0.0.10:8080:80
```

Random host port:

``` bash
-P
```

------------------------------------------------------------------------

# 22. Environment variables

``` bash
docker run -d \
  --name app01 \
  -e APP_ENV=production \
  -e APP_PORT=8080 \
  nginx
```

From env file:

``` bash
docker run -d \
  --env-file .env \
  --name app01 \
  nginx
```

------------------------------------------------------------------------

# 23. Restart policy

Always:

``` bash
docker run -d \
  --restart unless-stopped \
  --name web01 \
  nginx
```

Options:

``` text
no
always
on-failure
unless-stopped
```

Existing container:

``` bash
docker update \
  --restart unless-stopped \
  web01
```

------------------------------------------------------------------------

# 24. Docker networks

List:

``` bash
docker network ls
```

Inspect:

``` bash
docker network inspect bridge
```

Default networks:

``` text
bridge
host
none
```

------------------------------------------------------------------------

# 25. Default bridge

Default:

``` bash
docker run -d \
  --name web01 \
  nginx
```

Container нь default `bridge` network-д орно.

Inspect:

``` bash
docker network inspect bridge
```

Гэхдээ application stack-д өөрийн user-defined bridge network ашиглах нь
илүү цэвэр.

------------------------------------------------------------------------

# 26. Custom network

Create:

``` bash
docker network create app-net
```

List:

``` bash
docker network ls
```

Inspect:

``` bash
docker network inspect app-net
```

Container attach:

``` bash
docker run -d \
  --name web01 \
  --network app-net \
  nginx
```

------------------------------------------------------------------------

# 27. Container хооронд network

``` bash
docker network create app-net
```

``` bash
docker run -d \
  --name redis \
  --network app-net \
  redis
```

``` bash
docker run -d \
  --name app \
  --network app-net \
  myapp
```

`app` container нь:

``` text
redis
```

hostname-оор Redis рүү хандаж болно:

``` text
redis:6379
```

------------------------------------------------------------------------

# 28. Network connect/disconnect

Connect:

``` bash
docker network connect app-net web01
```

Disconnect:

``` bash
docker network disconnect app-net web01
```

Remove:

``` bash
docker network rm app-net
```

------------------------------------------------------------------------

# 29. Network inspect

``` bash
docker network inspect app-net
```

Харах зүйлс:

``` text
Subnet
Gateway
Containers
Driver
IPAM
```

------------------------------------------------------------------------

# 30. Network drivers

Common:

``` text
bridge
host
none
overlay
macvlan
ipvlan
```

List:

``` bash
docker network ls
```

------------------------------------------------------------------------

# 31. Host network

``` bash
docker run -d \
  --network host \
  --name web01 \
  nginx
```

Host network ашиглавал container host-ийн network namespace-тэй ойролцоо
ажиллана.

`-p` port mapping шаардлагагүй.

``` bash
docker run -d \
  --network host \
  nginx
```

------------------------------------------------------------------------

# 32. None network

``` bash
docker run -d \
  --network none \
  --name isolated01 \
  alpine \
  sleep 3600
```

Network interface бараг байхгүй isolated environment.

------------------------------------------------------------------------

# 33. Volumes гэж юу вэ?

Container filesystem:

``` text
Container
   |
   +-- writable layer
```

Container delete хийвэл энэ writable data устдаг.

Persistent data:

``` text
Container
   |
   v
Volume
   |
   v
Host storage
```

Docker-ийн volume болон bind mount нь persistent data хадгалах үндсэн
хоёр mount хэлбэр юм. citeturn0search8

------------------------------------------------------------------------

# 34. Volumes

List:

``` bash
docker volume ls
```

Create:

``` bash
docker volume create app-data
```

Inspect:

``` bash
docker volume inspect app-data
```

Delete:

``` bash
docker volume rm app-data
```

------------------------------------------------------------------------

# 35. Volume mount

``` bash
docker run -d \
  --name mysql \
  -v mysql-data:/var/lib/mysql \
  mysql:8
```

Volume:

``` text
mysql-data
      |
      v
/var/lib/mysql
      |
      v
MySQL container
```

Container delete:

``` bash
docker rm -f mysql
```

Volume үлдэнэ:

``` bash
docker volume ls
```

------------------------------------------------------------------------

# 36. `--mount` syntax

Modern explicit syntax:

``` bash
docker run -d \
  --name mysql \
  --mount type=volume,source=mysql-data,target=/var/lib/mysql \
  mysql:8
```

Volume:

``` text
source=mysql-data
```

Container path:

``` text
target=/var/lib/mysql
```

------------------------------------------------------------------------

# 37. Bind mount

Host directory:

``` bash
mkdir -p /data/docker/nginx
```

Run:

``` bash
docker run -d \
  --name nginx \
  -v /data/docker/nginx:/usr/share/nginx/html \
  nginx
```

Ингэснээр:

``` text
Host
/data/docker/nginx
        |
        v
Container
/usr/share/nginx/html
```

Bind mount нь host-ийн тодорхой path-ийг container-тэй share хийхэд
тохиромжтой. citeturn0search8

------------------------------------------------------------------------

# 38. Read-only mount

``` bash
docker run -d \
  --name nginx \
  -v /data/config:/etc/config:ro \
  nginx
```

Container `/etc/config`-ийг уншина, бичиж чадахгүй.

------------------------------------------------------------------------

# 39. Volume vs Bind mount

``` text
Volume
  Docker managed
  mysql-data:/var/lib/mysql

Bind mount
  User managed
  /data/mysql:/var/lib/mysql
```

Use volume when:

``` text
DB data
Docker-managed application data
```

Use bind mount when:

``` text
Configuration
Logs
Source code
Host-managed files
```

------------------------------------------------------------------------

# 40. Dockerfile

Dockerfile бол image build хийх recipe.

Example:

``` dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

Build:

``` bash
docker build -t my-nginx:1.0 .
```

Run:

``` bash
docker run -d \
  --name my-nginx \
  -p 8080:80 \
  my-nginx:1.0
```

------------------------------------------------------------------------

# 41. Dockerfile common instructions

``` text
FROM
RUN
COPY
ADD
WORKDIR
ENV
ARG
EXPOSE
USER
ENTRYPOINT
CMD
HEALTHCHECK
VOLUME
```

Example:

``` dockerfile
FROM python:3.13-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=8080

EXPOSE 8080

CMD ["python", "app.py"]
```

------------------------------------------------------------------------

# 42. `CMD` vs `ENTRYPOINT`

CMD:

``` dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

Default command.

ENTRYPOINT:

``` dockerfile
ENTRYPOINT ["python"]
```

Main executable.

Combined:

``` dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

→

``` text
python app.py
```

------------------------------------------------------------------------

# 43. Build context

``` bash
docker build -t myapp:1.0 .
```

`.` нь build context.

Тиймээс unnecessary files оруулахгүй байх.

`.dockerignore`:

``` text
.git
.gitignore
node_modules
__pycache__
*.log
.env
terraform.tfstate
```

------------------------------------------------------------------------

# 44. Build cache

``` bash
docker build -t myapp:1.0 .
```

Cache ашиглана.

No cache:

``` bash
docker build --no-cache -t myapp:1.0 .
```

Pull latest base:

``` bash
docker build --pull -t myapp:1.0 .
```

------------------------------------------------------------------------

# 45. Buildx

Check:

``` bash
docker buildx version
```

Builders:

``` bash
docker buildx ls
```

Create:

``` bash
docker buildx create --name mybuilder --use
```

Build:

``` bash
docker buildx build \
  -t myapp:1.0 \
  .
```

Multi-platform:

``` bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.example.com/myapp:1.0 \
  --push \
  .
```

------------------------------------------------------------------------

# 46. Tags

``` bash
docker tag myapp:1.0 myapp:latest
```

Registry tag:

``` bash
docker tag myapp:1.0 \
  registry.example.com/team/myapp:1.0
```

List:

``` bash
docker image ls
```

------------------------------------------------------------------------

# 47. Docker Registry

Login:

``` bash
docker login
```

Specific registry:

``` bash
docker login registry.example.com
```

Push:

``` bash
docker push registry.example.com/team/myapp:1.0
```

Pull:

``` bash
docker pull registry.example.com/team/myapp:1.0
```

------------------------------------------------------------------------

# 48. Docker Hub

Login:

``` bash
docker login
```

Tag:

``` bash
docker tag myapp:1.0 USERNAME/myapp:1.0
```

Push:

``` bash
docker push USERNAME/myapp:1.0
```

Pull:

``` bash
docker pull USERNAME/myapp:1.0
```

------------------------------------------------------------------------

# 49. Compose гэж юу вэ?

Docker Compose нь олон container application stack-ийг YAML file-аар
тодорхойлж, бүх service/network/volume-ийг нэг lifecycle болгон
удирдана. citeturn0search2turn0search11

Typical:

``` text
compose.yaml
     |
     +-- app
     +-- nginx
     +-- mysql
     +-- redis
     |
     +-- networks
     +-- volumes
```

------------------------------------------------------------------------

# 50. Basic Compose

`compose.yaml`:

``` yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
```

Start:

``` bash
docker compose up -d
```

Status:

``` bash
docker compose ps
```

Logs:

``` bash
docker compose logs
```

Follow:

``` bash
docker compose logs -f
```

Stop:

``` bash
docker compose down
```

------------------------------------------------------------------------

# 51. Compose project

Current directory:

``` bash
docker compose up -d
```

Compose automatically creates a project network.

Typical:

``` text
myproject_default
```

Check:

``` bash
docker network ls
```

------------------------------------------------------------------------

# 52. Compose full stack example

``` yaml
services:

  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "8080:80"
    depends_on:
      - app
    networks:
      - frontend

  app:
    image: nginx:alpine
    container_name: app
    networks:
      - frontend
      - backend

  redis:
    image: redis:alpine
    container_name: redis
    networks:
      - backend

networks:
  frontend:
  backend:
```

Compose creates services and networks together. citeturn0search12

------------------------------------------------------------------------

# 53. Compose commands

Start:

``` bash
docker compose up -d
```

Build:

``` bash
docker compose build
```

Build + start:

``` bash
docker compose up -d --build
```

Stop:

``` bash
docker compose stop
```

Start existing:

``` bash
docker compose start
```

Restart:

``` bash
docker compose restart
```

Down:

``` bash
docker compose down
```

Down + volumes:

``` bash
docker compose down -v
```

Logs:

``` bash
docker compose logs -f
```

Specific service:

``` bash
docker compose logs -f app
```

Execute:

``` bash
docker compose exec app sh
```

Run one-off:

``` bash
docker compose run --rm app sh
```

------------------------------------------------------------------------

# 54. Compose config validation

``` bash
docker compose config
```

Quiet validation:

``` bash
docker compose config -q
```

This is extremely useful before deployment.

------------------------------------------------------------------------

# 55. Compose rebuild workflow

Code/config changed:

``` bash
docker compose build
```

Then:

``` bash
docker compose up -d
```

One command:

``` bash
docker compose up -d --build
```

Force recreate:

``` bash
docker compose up -d --force-recreate
```

------------------------------------------------------------------------

# 56. Compose environment variables

`.env`:

``` env
MYSQL_ROOT_PASSWORD=change-me
MYSQL_DATABASE=app
MYSQL_USER=app
MYSQL_PASSWORD=change-me
```

Compose:

``` yaml
services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

Do not commit real secrets into Git.

------------------------------------------------------------------------

# 57. Compose volumes

``` yaml
services:
  mysql:
    image: mysql:8
    volumes:
      - mysql-data:/var/lib/mysql

volumes:
  mysql-data:
```

List:

``` bash
docker volume ls
```

------------------------------------------------------------------------

# 58. Compose bind mount

``` yaml
services:
  nginx:
    image: nginx:alpine
    volumes:
      - ./html:/usr/share/nginx/html:ro
```

------------------------------------------------------------------------

# 59. Compose network

``` yaml
services:

  app:
    image: myapp:1.0
    networks:
      - app-net

  db:
    image: mysql:8
    networks:
      - app-net

networks:
  app-net:
```

App:

``` text
db:3306
```

гэж DB рүү хандана.

------------------------------------------------------------------------

# 60. Compose healthcheck

``` yaml
services:

  app:
    image: myapp:1.0

    healthcheck:
      test:
        - CMD
        - curl
        - -f
        - http://localhost:8080/health
      interval: 30s
      timeout: 5s
      retries: 3
```

Status:

``` bash
docker compose ps
```

------------------------------------------------------------------------

# 61. Compose dependency

``` yaml
services:

  app:
    image: myapp:1.0
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mysql:8
    healthcheck:
      test:
        - CMD
        - mysqladmin
        - ping
        - -h
        - localhost
      interval: 10s
      timeout: 5s
      retries: 5
```

`depends_on` нь startup ordering-ийг зохицуулахад тусална; application
readiness-ийг healthcheck-ээр тодорхойлох нь илүү найдвартай.

------------------------------------------------------------------------

# 62. Docker secrets

Production application дээр:

``` text
password
API key
TLS private key
token
```

зэргийг image-д hardcode хийж болохгүй.

Compose secrets mechanism ашиглаж болно:

``` yaml
services:
  app:
    image: myapp:1.0
    secrets:
      - db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

------------------------------------------------------------------------

# 63. Docker labels

``` bash
docker run -d \
  --label environment=dev \
  --label team=platform \
  nginx
```

Inspect:

``` bash
docker inspect web01 \
  --format '{{json .Config.Labels}}'
```

------------------------------------------------------------------------

# 64. Resource limits

CPU:

``` bash
docker run -d \
  --cpus=2 \
  nginx
```

Memory:

``` bash
docker run -d \
  --memory=1g \
  nginx
```

CPU + memory:

``` bash
docker run -d \
  --cpus=2 \
  --memory=2g \
  nginx
```

Existing:

``` bash
docker update \
  --cpus=2 \
  --memory=2g \
  web01
```

------------------------------------------------------------------------

# 65. Health / process troubleshooting

``` bash
docker ps
```

``` bash
docker inspect web01
```

``` bash
docker logs web01
```

``` bash
docker top web01
```

``` bash
docker stats web01
```

Shell:

``` bash
docker exec -it web01 sh
```

------------------------------------------------------------------------

# 66. Exit codes

Container exited:

``` bash
docker ps -a
```

Inspect:

``` bash
docker inspect web01 \
  --format '{{.State.ExitCode}}'
```

OOM:

``` bash
docker inspect web01 \
  --format '{{.State.OOMKilled}}'
```

------------------------------------------------------------------------

# 67. OOM troubleshooting

``` bash
docker stats
```

Host:

``` bash
free -h
```

Container:

``` bash
docker inspect web01 \
  --format '{{.HostConfig.Memory}}'
```

Kernel:

``` bash
dmesg -T | grep -i oom
```

------------------------------------------------------------------------

# 68. Disk full troubleshooting

Host:

``` bash
df -h
```

Docker:

``` bash
docker system df
```

Detailed:

``` bash
docker system df -v
```

Large Docker directory:

``` bash
sudo du -sh /var/lib/docker/*
```

Do not blindly delete `/var/lib/docker`.

Use Docker prune commands.

------------------------------------------------------------------------

# 69. Cleanup

Stopped containers:

``` bash
docker container prune
```

Unused images:

``` bash
docker image prune
```

All unused images:

``` bash
docker image prune -a
```

Unused volumes:

``` bash
docker volume prune
```

Unused networks:

``` bash
docker network prune
```

General:

``` bash
docker system prune
```

Aggressive:

``` bash
docker system prune -a
```

Include volumes:

``` bash
docker system prune -a --volumes
```

> `--volumes` болон `-a` нь production host дээр болгоомжтой хэрэглэ.
> Persistent database data устах эрсдэлтэй.

------------------------------------------------------------------------

# 70. Find unused resources

Containers:

``` bash
docker ps -a
```

Images:

``` bash
docker image ls
```

Volumes:

``` bash
docker volume ls
```

Networks:

``` bash
docker network ls
```

Disk:

``` bash
docker system df -v
```

------------------------------------------------------------------------

# 71. Container filesystem

``` bash
docker exec web01 df -h
```

Mounts:

``` bash
docker inspect web01 \
  --format '{{json .Mounts}}'
```

Writable layer size:

``` bash
docker ps -s
```

------------------------------------------------------------------------

# 72. Copy files

Host → container:

``` bash
docker cp ./config.yaml web01:/etc/config.yaml
```

Container → host:

``` bash
docker cp web01:/etc/nginx/nginx.conf ./nginx.conf
```

Directory:

``` bash
docker cp ./config web01:/etc/
```

------------------------------------------------------------------------

# 73. Commit container to image

``` bash
docker commit web01 my-web:debug
```

List:

``` bash
docker images
```

> `docker commit` нь reproducible production image build-ийн оронд
> Dockerfile ашиглахтай адилгүй. Debug/quick snapshot-д илүү
> тохиромжтой.

------------------------------------------------------------------------

# 74. Export / import

Container filesystem export:

``` bash
docker export web01 > web01.tar
```

Import:

``` bash
cat web01.tar | docker import - my-web:imported
```

Image save:

``` bash
docker save -o nginx.tar nginx:latest
```

Load:

``` bash
docker load -i nginx.tar
```

------------------------------------------------------------------------

# 75. Docker inspect useful formats

Name:

``` bash
docker inspect web01 \
  --format '{{.Name}}'
```

IP:

``` bash
docker inspect web01 \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Image:

``` bash
docker inspect web01 \
  --format '{{.Config.Image}}'
```

Status:

``` bash
docker inspect web01 \
  --format '{{.State.Status}}'
```

PID:

``` bash
docker inspect web01 \
  --format '{{.State.Pid}}'
```

------------------------------------------------------------------------

# 76. Container hostname

``` bash
docker run -d \
  --name web01 \
  --hostname web01 \
  nginx
```

Check:

``` bash
docker exec web01 hostname
```

------------------------------------------------------------------------

# 77. Container user

``` bash
docker exec web01 id
```

Dockerfile:

``` dockerfile
USER 1000
```

Run:

``` bash
docker run --user 1000:1000 nginx
```

Production application дээр unnecessary root process-оос зайлсхий.

------------------------------------------------------------------------

# 78. Read-only root filesystem

``` bash
docker run -d \
  --read-only \
  nginx
```

Application runtime-д write хийх шаардлагатай бол `tmpfs` эсвэл volume
mount ашиглана.

------------------------------------------------------------------------

# 79. tmpfs

``` bash
docker run -d \
  --tmpfs /tmp \
  nginx
```

Энэ data host дээр persistent volume хэлбэрээр хадгалагдахгүй.

------------------------------------------------------------------------

# 80. Security basics

Production container:

``` text
- Non-root user
- Minimal base image
- Read-only filesystem when possible
- Drop unnecessary capabilities
- Resource limits
- No unnecessary host mounts
- Secrets outside image
- Pin image versions
- Scan images
- Keep Docker Engine updated
```

Image:

``` dockerfile
FROM alpine:3.22
```

нь:

``` dockerfile
FROM alpine:latest
```

-аас deployment reproducibility талаасаа илүү тодорхой.

------------------------------------------------------------------------

# 81. Capabilities

Container:

``` bash
docker run \
  --cap-drop=ALL \
  nginx
```

Шаардлагатай capability-г тодорхой нэмэх:

``` bash
docker run \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  nginx
```

Blindly `--privileged` ашиглахаас зайлсхий.

------------------------------------------------------------------------

# 82. Privileged container

``` bash
docker run --privileged ...
```

Энэ нь маш өндөр эрх өгдөг.

Production application container дээр шаардлагагүй бол:

`text DO NOT USE`

------------------------------------------------------------------------

# 83. Host filesystem mount security

Эрсдэлтэй:

``` bash
-v /:/host
```

эсвэл:

``` bash
-v /var/run/docker.sock:/var/run/docker.sock
```

Docker socket mount хийсэн container Docker daemon-ийг удирдах боломжтой
тул өндөр эрсдэлтэй.

------------------------------------------------------------------------

# 84. Docker socket

``` bash
ls -l /var/run/docker.sock
```

Docker daemon endpoint:

`text unix:///var/run/docker.sock`

Check:

``` bash
docker context ls
```

------------------------------------------------------------------------

# 85. Docker contexts

List:

``` bash
docker context ls
```

Current:

``` bash
docker context show
```

Create SSH context:

``` bash
docker context create remote \
  --docker "host=ssh://user@server"
```

Use:

``` bash
docker context use remote
```

Back:

``` bash
docker context use default
```

------------------------------------------------------------------------

# 86. Remote Docker

``` bash
docker -H ssh://user@server ps
```

Эсвэл context:

``` bash
docker context use remote
```

``` bash
docker ps
```

------------------------------------------------------------------------

# 87. Docker daemon configuration

Common config:

``` text
/etc/docker/daemon.json
```

View:

``` bash
sudo cat /etc/docker/daemon.json
```

After change:

``` bash
sudo systemctl restart docker
```

Check:

``` bash
docker info
```

------------------------------------------------------------------------

# 88. Change Docker data root

Example:

``` json
{
  "data-root": "/data/docker"
}
```

Create:

``` bash
sudo mkdir -p /data/docker
```

Edit:

``` bash
sudo nano /etc/docker/daemon.json
```

Restart:

``` bash
sudo systemctl restart docker
```

Check:

``` bash
docker info | grep "Docker Root Dir"
```

> Existing `/var/lib/docker` data migration хийх бол зөвхөн
> `daemon.json` солихоос өмнө data migration/backup strategy-гаа
> төлөвлө.

------------------------------------------------------------------------

# 89. Docker firewall

Docker published ports нь host firewall behavior-тэй шууд холбоотой.

Хэрэв:

``` bash
-p 8080:80
```

хийвэл Docker iptables/nftables rules үүсгэнэ.

Шалгах:

``` bash
sudo nft list ruleset
```

``` bash
sudo iptables -L -n
```

Docker-ийн port publishing нь firewall configuration-тэй зөрчилдөх
боломжтой тул production host дээр firewall architecture-аа тусад нь
төлөвлө. Official Docker documentation мөн firewall compatibility-ийн
анхааруулга өгдөг. citeturn0search6

------------------------------------------------------------------------

# 90. Docker + UFW / firewalld

UFW/firewalld ашигладаг бол:

``` bash
sudo ufw status
```

эсвэл:

``` bash
sudo firewall-cmd --state
```

Docker published ports нь зарим firewall rules-ийг bypass хийх нөхцөл
үүсгэж болно.

Production дээр:

``` text
Internet
   |
 Firewall / LB
   |
 Docker host
   |
 Published ports
```

гэсэн architecture-аа тодорхой төлөвлө.

------------------------------------------------------------------------

# 91. DNS inside Docker

Container:

``` bash
docker exec web01 cat /etc/resolv.conf
```

Network inspect:

``` bash
docker network inspect app-net
```

User-defined bridge network дээр service/container name resolution
ашиглах нь Compose stack-д маш тохиромжтой.

------------------------------------------------------------------------

# 92. MySQL + Docker

Example:

``` bash
docker volume create mysql-data
```

``` bash
docker run -d \
  --name mysql \
  --restart unless-stopped \
  -e MYSQL_ROOT_PASSWORD='change-me' \
  -e MYSQL_DATABASE=app \
  -e MYSQL_USER=app \
  -e MYSQL_PASSWORD='change-me' \
  -v mysql-data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8
```

Check:

``` bash
docker logs mysql
```

``` bash
docker exec mysql mysql -uapp -p
```

> Real production passwords-ийг shell history-д үлдээхгүй байх strategy
> ашигла.

------------------------------------------------------------------------

# 93. Redis + Docker

``` bash
docker run -d \
  --name redis \
  --restart unless-stopped \
  redis:alpine
```

Check:

``` bash
docker exec redis redis-cli ping
```

Expected:

``` text
PONG
```

------------------------------------------------------------------------

# 94. Nginx + Docker

``` bash
docker run -d \
  --name nginx \
  --restart unless-stopped \
  -p 80:80 \
  nginx:alpine
```

Check:

``` bash
curl http://localhost
```

------------------------------------------------------------------------

# 95. Nginx config bind mount

``` bash
mkdir -p /data/docker/nginx/conf.d
```

``` bash
docker run -d \
  --name nginx \
  -p 80:80 \
  -v /data/docker/nginx/conf.d:/etc/nginx/conf.d:ro \
  nginx:alpine
```

Config test:

``` bash
docker exec nginx nginx -t
```

Reload:

``` bash
docker exec nginx nginx -s reload
```

------------------------------------------------------------------------

# 96. Practical Compose application

Directory:

``` text
myapp/
├── compose.yaml
├── .env
├── app/
│   └── ...
└── nginx/
    └── nginx.conf
```

Compose:

``` yaml
services:

  app:
    build: ./app
    restart: unless-stopped
    networks:
      - backend

  db:
    image: mysql:8
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - backend

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      - app
    networks:
      - frontend
      - backend

networks:
  frontend:
  backend:

volumes:
  mysql-data:
```

Start:

``` bash
docker compose up -d --build
```

------------------------------------------------------------------------

# 97. Compose deployment workflow

``` text
Git
 |
 v
compose.yaml
 |
 v
docker compose config
 |
 v
docker compose pull
 |
 v
docker compose build
 |
 v
docker compose up -d
 |
 v
docker compose ps
 |
 v
docker compose logs
```

Commands:

``` bash
docker compose config -q
```

``` bash
docker compose pull
```

``` bash
docker compose build
```

``` bash
docker compose up -d
```

``` bash
docker compose ps
```

``` bash
docker compose logs -f
```

------------------------------------------------------------------------

# 98. Update image

Current:

``` bash
docker image ls
```

Pull:

``` bash
docker pull nginx:1.28
```

Recreate:

``` bash
docker compose up -d
```

Compose stack:

``` bash
docker compose pull
docker compose up -d
```

------------------------------------------------------------------------

# 99. Zero-downtime note

Энгийн:

``` bash
docker compose up -d
```

нь Kubernetes-ийн rolling deployment-тэй адил production zero-downtime
guarantee биш.

High availability шаардлагатай бол:

``` text
Load Balancer
      |
 +----+----+
 |         |
App-01   App-02
```

эсвэл Kubernetes зэрэг orchestrator ашиглана.

------------------------------------------------------------------------

# 100. Docker Compose vs Kubernetes

Compose:

``` text
Single host
Small/medium stack
Development
Lab
Simple production
```

Kubernetes:

``` text
Multiple nodes
Scheduling
Self-healing
Rolling deployments
Service discovery
Scaling
HA
```

Compose нь Kubernetes-ийн replacement биш.

------------------------------------------------------------------------

# 101. Docker Compose file structure

Current recommended format нь Compose Specification. Legacy
`version: "2"` / `version: "3"` syntax-ийг тусад нь заавал сонгох
шаардлагагүй. citeturn0search11

Basic:

``` yaml
services:
  app:
    image: myapp:1.0

networks:
  app-net:

volumes:
  app-data:
```

------------------------------------------------------------------------

# 102. Docker health overview

Container:

``` bash
docker ps
```

Health:

``` bash
docker inspect web01 \
  --format '{{json .State.Health}}'
```

Compose:

``` bash
docker compose ps
```

------------------------------------------------------------------------

# 103. Docker logs architecture

``` text
Application
    |
    v
stdout / stderr
    |
    v
Docker logging driver
    |
    +-- json-file
    +-- local
    +-- syslog
    +-- journald
    +-- fluentd
    +-- gelf
    +-- awslogs
```

Default logging configuration:

``` bash
docker info
```

------------------------------------------------------------------------

# 104. Logging driver

Inspect:

``` bash
docker inspect web01 \
  --format '{{.HostConfig.LogConfig.Type}}'
```

Daemon config example:

``` json
{
  "log-driver": "local"
}
```

Restart:

``` bash
sudo systemctl restart docker
```

Production logging architecture:

``` text
Docker
  |
  v
stdout/stderr
  |
  v
Logging driver / collector
  |
  +-- Loki
  +-- Fluent Bit
  +-- Graylog
  +-- ELK
```

------------------------------------------------------------------------

# 105. Docker monitoring

Basic:

``` bash
docker stats
```

Host:

``` bash
docker info
```

Container:

``` bash
docker inspect
```

Production:

``` text
Prometheus
   |
   +-- node_exporter
   +-- cAdvisor
   |
   v
Grafana
```

Logs:

``` text
Docker
  |
Fluent Bit
  |
Loki
  |
Grafana
```

------------------------------------------------------------------------

# 106. Docker troubleshooting checklist

## Container not starting

``` bash
docker ps -a
```

``` bash
docker logs <container>
```

``` bash
docker inspect <container>
```

## Port unavailable

``` bash
ss -lntp
```

``` bash
docker ps
```

``` bash
docker port <container>
```

## Network issue

``` bash
docker network ls
```

``` bash
docker network inspect <network>
```

``` bash
docker exec <container> ip addr
```

## Disk issue

``` bash
df -h
```

``` bash
docker system df -v
```

## Memory issue

``` bash
docker stats
```

``` bash
dmesg -T | grep -i oom
```

------------------------------------------------------------------------

# 107. Docker container lifecycle mental model

``` text
                 IMAGE
                   |
              docker run
                   |
                   v
               CREATED
                   |
                   v
                RUNNING
                /     \
               /       \
            stop       kill
             |           |
             v           v
           EXITED      EXITED
             |
             v
           start
             |
             v
           RUNNING
```

Remove:

``` text
docker rm
```

image remove:

``` text
docker rmi
```

Container болон image хоёр тусдаа object.

------------------------------------------------------------------------

# 108. Image vs Container

``` text
Image
  = immutable template

Container
  = running instance of image
```

Жишээ:

``` text
nginx:1.28
   |
   +-- web01
   +-- web02
   +-- web03
```

Нэг image-аас олон container ажиллуулж болно.

------------------------------------------------------------------------

# 109. Volume lifecycle

``` text
docker volume create db-data
             |
             v
       MySQL container
             |
             v
      /var/lib/mysql
```

Container:

``` bash
docker rm -f mysql
```

Volume:

``` bash
docker volume ls
```

data үлдэнэ.

Volume delete:

``` bash
docker volume rm db-data
```

→ data устна.

------------------------------------------------------------------------

# 110. Network lifecycle

``` bash
docker network create app-net
```

``` bash
docker run -d --network app-net --name app myapp
```

``` bash
docker run -d --network app-net --name db mysql:8
```

``` text
app
 |
 +---- app-net ----+
                   |
                  db
```

Delete:

``` bash
docker network rm app-net
```

Container attached байвал эхлээд detach/remove хийх шаардлагатай.

------------------------------------------------------------------------

# 111. Recommended project structure

Single app:

``` text
app/
├── Dockerfile
├── .dockerignore
├── compose.yaml
├── .env.example
├── src/
└── README.md
```

Infrastructure:

``` text
docker/
├── compose/
│   ├── monitoring/
│   ├── database/
│   ├── reverse-proxy/
│   └── applications/
├── images/
│   ├── app/
│   └── nginx/
└── README.md
```

------------------------------------------------------------------------

# 112. Git best practices

Commit:

``` text
Dockerfile
compose.yaml
.dockerignore
.env.example
```

Do NOT commit:

``` text
.env
*.pem
*.key
password files
database dumps
Docker volumes
```

`.gitignore`:

``` gitignore
.env
*.pem
*.key
*.crt
*.log
```

------------------------------------------------------------------------

# 113. Docker + GitLab CI/CD

Typical:

``` text
Git push
   |
   v
GitLab CI
   |
   +-- docker build
   |
   +-- test
   |
   +-- security scan
   |
   +-- docker push
   |
   v
Registry
   |
   v
Production
   |
docker compose pull
docker compose up -d
```

------------------------------------------------------------------------

# 114. Build and push example

``` bash
docker build \
  -t registry.example.com/team/app:1.0.0 \
  .
```

Login:

``` bash
docker login registry.example.com
```

Push:

``` bash
docker push registry.example.com/team/app:1.0.0
```

Server:

``` bash
docker pull registry.example.com/team/app:1.0.0
```

------------------------------------------------------------------------

# 115. Immutable deployment mindset

Avoid:

``` text
latest
```

for critical production deployment.

Prefer:

``` text
app:1.4.7
```

or immutable digest:

``` text
app@sha256:...
```

Deployment:

``` text
Git commit
    |
    v
Image tag / digest
    |
    v
Registry
    |
    v
Production
```

------------------------------------------------------------------------

# 116. Useful command aliases

Optional shell aliases:

``` bash
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker image ls'
alias dn='docker network ls'
alias dv='docker volume ls'
```

------------------------------------------------------------------------

# 117. Full Docker environment inspection

Copy-paste:

``` bash
echo "===== DOCKER VERSION ====="
docker version

echo
echo "===== DOCKER INFO ====="
docker info

echo
echo "===== CONTAINERS ====="
docker ps -a

echo
echo "===== IMAGES ====="
docker image ls

echo
echo "===== NETWORKS ====="
docker network ls

echo
echo "===== VOLUMES ====="
docker volume ls

echo
echo "===== DISK USAGE ====="
docker system df
```

------------------------------------------------------------------------

# 118. Daily operations cheat sheet

## Images

``` bash
docker image ls
docker pull nginx:alpine
docker image inspect nginx:alpine
docker image rm nginx:alpine
```

## Containers

``` bash
docker ps
docker ps -a
docker start app
docker stop app
docker restart app
docker rm app
docker logs -f app
docker exec -it app sh
docker inspect app
docker stats
```

## Network

``` bash
docker network ls
docker network inspect app-net
docker network create app-net
docker network connect app-net app
docker network disconnect app-net app
docker network rm app-net
```

## Volumes

``` bash
docker volume ls
docker volume create app-data
docker volume inspect app-data
docker volume rm app-data
```

## Build

``` bash
docker build -t myapp:1.0 .
docker tag myapp:1.0 registry.example.com/myapp:1.0
docker push registry.example.com/myapp:1.0
```

## Compose

``` bash
docker compose config -q
docker compose up -d
docker compose ps
docker compose logs -f
docker compose exec app sh
docker compose pull
docker compose up -d --build
docker compose down
```

------------------------------------------------------------------------

# 119. Most useful commands table

  Task                 Command
  -------------------- ----------------------------------
  Docker version       `docker version`
  System info          `docker info`
  Running containers   `docker ps`
  All containers       `docker ps -a`
  Images               `docker image ls`
  Pull image           `docker pull nginx`
  Run container        `docker run -d nginx`
  Start                `docker start app`
  Stop                 `docker stop app`
  Restart              `docker restart app`
  Remove               `docker rm app`
  Logs                 `docker logs app`
  Follow logs          `docker logs -f app`
  Shell                `docker exec -it app sh`
  Inspect              `docker inspect app`
  Stats                `docker stats`
  Networks             `docker network ls`
  Network inspect      `docker network inspect app-net`
  Create network       `docker network create app-net`
  Volumes              `docker volume ls`
  Create volume        `docker volume create data`
  Volume inspect       `docker volume inspect data`
  Build                `docker build -t app:1.0 .`
  Login registry       `docker login`
  Push                 `docker push image:tag`
  Pull                 `docker pull image:tag`
  Compose up           `docker compose up -d`
  Compose down         `docker compose down`
  Compose status       `docker compose ps`
  Compose logs         `docker compose logs -f`
  Compose exec         `docker compose exec app sh`
  Disk usage           `docker system df`
  Cleanup              `docker system prune`

------------------------------------------------------------------------

# 120. Final mental model

Docker-ийг дараах байдлаар цээжил:

``` text
                         DOCKER ENGINE
                              |
             +----------------+----------------+
             |                |                |
           IMAGE          CONTAINER          NETWORK
             |                |                |
             |                |                |
             +----------------+----------------+
                              |
                           VOLUME
                              |
                         persistent data
```

Application stack:

``` text
                 compose.yaml
                      |
       +--------------+--------------+
       |              |              |
      nginx          app             db
       |              |              |
       +--------------+--------------+
                      |
                 Docker network
                      |
                   volumes
```

Build/deploy:

``` text
Dockerfile
    |
    v
docker build
    |
    v
Image
    |
    v
Registry
    |
    v
docker pull
    |
    v
Container
```

Infrastructure stack:

``` text
Terraform
    |
    v
Incus / VM
    |
    v
Linux
    |
    v
Docker Engine
    |
    v
Docker Compose
    |
    +-- nginx
    +-- app
    +-- mysql
    +-- redis
```

Ингэж mental model-оо суулгавал Docker CLI-ийн ихэнх command-ийг
объектын lifecycle-ээр нь ойлгож чадна:

``` text
IMAGE
  ↓
CONTAINER
  ↓
NETWORK
  ↓
VOLUME
  ↓
COMPOSE
  ↓
REGISTRY
  ↓
CI/CD
```

------------------------------------------------------------------------

# 121. Official references

Docker Engine:

https://docs.docker.com/engine/ citeturn0search1

Docker Engine installation:

https://docs.docker.com/engine/install/ citeturn0search0

Docker Compose:

https://docs.docker.com/compose/ citeturn0search2

Compose file reference:

https://docs.docker.com/compose/compose-file/ citeturn0search11

Docker CLI reference:

https://docs.docker.com/reference/cli/docker/ citeturn0search9

Docker storage:

https://docs.docker.com/engine/storage/ citeturn0search8

Docker networking:

https://docs.docker.com/engine/network/ citeturn0search1

------------------------------------------------------------------------

# 122. Quick reference --- first 20 commands

``` bash
docker version
docker info
docker ps
docker ps -a
docker image ls
docker pull nginx
docker run -d --name nginx -p 8080:80 nginx
docker logs nginx
docker exec -it nginx bash
docker inspect nginx
docker stats
docker stop nginx
docker start nginx
docker restart nginx
docker rm nginx
docker network ls
docker network inspect bridge
docker volume ls
docker system df
docker compose up -d
```

Эдгээр 20 command-ийг сайн ойлгочихвол Docker-ийн өдөр тутмын 80%-ийн
operation-ийг хийж чадна.
