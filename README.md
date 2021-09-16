# best-Dockerfile-for-spa

适用于 Vue.js 和 React.js 项目的最完美的 Docker 镜像构建文件。


## Dockerfile 内容

```docker
FROM node:alpine as builder

WORKDIR /app

COPY package.json /app/package.json
RUN npm install --registry=https://registry.npm.taobao.org

COPY . /app
RUN npm run build

FROM nginx:alpine as server

COPY --from=builder /app/dist /usr/share/nginx/html
```


## 配置文件遵循以下几项原则：

**1) 使用最小基础镜像**

如果需要指定 Node 版本，可以用类似 `node:14.9-slim` 这样的镜像，在[这里](https://hub.docker.com/_/node)你可以找到更多的选择。

这里第一阶段使用的 `node:alpine` 是 75M 左右，而第二阶段用于生成最终镜像的 `nginx:alpine` 仅 16M 左右。

**2) 多阶段构建**

回想我们的终极目标是什么？

事实上我们最终需要的仅仅是打包之后的静态文件和一个 nginx 服务器，而 node 环境、 node_modules 文件夹和源码并不是我们最终需要的内容，而且通常 node_modules 文件夹会占据相当大的空间，少则几百 M 多则 1 G，如果把不需要的文件放到构建镜像中实属浪费。

这种情况下就可以使用多阶段构建的方式，将整个过程分为两个阶段：
  1. 第一阶段是在 node 环境中对源码打包编译
  2. 第二阶段将上一阶段中编译出来的文件拷贝出来放入一个纯净的 nginx 环境。

这个方式可以获得极简的镜像，其实你看一些带有 `alpine` 标签的官方镜像会发现，它们甚至连 `bash` 都没有，只有最核心的功能，可以说真的很简洁了。

**3) 缓存 node modules**

安装 npm 依赖是整个构建过程中非常耗时的一个步骤，时长取决于依赖包的数量和机器的网络情况，而且关键的一点是在依赖包没有发生变化的情况下，完全可以使用上次安装过的依赖包而不需要每次构建时都重新安装。

所以这里的一个小技巧是在拷贝整个项目源码之前，将 `package.json` 单独拷贝到镜像中，然后执行 `npm install` 操作，只要 `package.json` 没有发生变化，`npm install` 就会直接利用上次 `install` 的缓存。如果 `package.json` 发生了变化，那么就无法使用缓存，只能老老实实重新安装依赖。

这个技巧可以有效利用 docker 的缓存功能，节省构建时间。


## 使用

适用于典型的前端单页面应用（vue.js 和 react.js），直接将 `Dockerfile` 和 `.dockerignore` 文件拷贝至项目根目录即可。

假设本次构建的镜像名称为 front，标签为 v0.1，相关命令如下：

+ **构建镜像**

```bash
# 最后的点表示当前上下文，不可省略
docker build -t front:v0.1 .
```

+ **后台运行容器**

```bash
docker run -d -p 8000:80 front:v0.1
```

## 其他

多阶段构建会产生一些名称和标签都为 `none` 的 image，如下：

![none](./assets/docker-none.png)

这是镜像构建过程中第一阶段产生的镜像，可以作为以后再次构建镜像的缓存，不建议删除。

当然，如果真的想要删除掉它们，可以用下面命令进行删除：

```bash
docker stop $(docker ps -a | grep "Exited" | awk '{print $1 }')

docker rm $(docker ps -a | grep "Exited" | awk '{print $1 }')

docker rmi $(docker images | grep "none" | awk '{print $3}')
```
<!-- 

# 更新Alpine的软件源为国内（清华大学）的站点
# RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.4/main/" > /etc/apk/repositories

# 默认没有 bash，如果需要，解开注释安装 bash
# RUN apk update \
#   && apk upgrade \
#   && apk add --no-cache bash \
#   bash-doc \
#   bash-completion \
#   && rm -rf /var/cache/apk/* \
#   && /bin/bash -->
