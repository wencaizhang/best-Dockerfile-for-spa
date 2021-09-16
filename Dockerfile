# 第一阶段（构建阶段）
FROM node:alpine as builder

WORKDIR /app

COPY package.json /app/package.json
RUN npm install --registry=https://registry.npm.taobao.org

COPY . /app
RUN npm run build

# 第二阶段
FROM nginx:alpine as server
COPY --from=builder /app/dist/ /var/www/html/
COPY ./nginx.conf /etc/nginx/
CMD ["nginx"]