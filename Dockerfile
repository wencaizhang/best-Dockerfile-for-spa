FROM node:alpine as builder

# 更新Alpine的软件源为国内（清华大学）的站点
# RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.4/main/" > /etc/apk/repositories

# 默认没有 bash，如果需要，解开注释安装 bash
# RUN apk update \
#   && apk upgrade \
#   && apk add --no-cache bash \
#   bash-doc \
#   bash-completion \
#   && rm -rf /var/cache/apk/* \
#   && /bin/bash

WORKDIR /app

COPY package.json /app/package.json
RUN npm install --registry=https://registry.npm.taobao.org

COPY . /app
RUN npm run build

FROM nginx:alpine as server

COPY --from=builder /app/dist /usr/share/nginx/html