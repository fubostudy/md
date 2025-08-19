FROM node:20-alpine AS build
WORKDIR /app

# 仅复制包管理文件，利用缓存层
COPY package*.json ./
RUN npm ci --no-audit --no-fund --ignore-scripts

# 复制源码并构建（默认部署到根路径 /）
COPY . .
ENV CI=1

# 切换构建目标：
# - ROOT（默认）：部署到根路径 /
# - SUBPATH：部署到子路径 /md/
ARG BUILD_TARGET=ROOT
RUN if [ "$BUILD_TARGET" = "SUBPATH" ]; then npm run build; else npm run build:h5-netlify; fi

# 运行时镜像：使用 Nginx 提供静态资源
FROM nginx:1.25-alpine

# 覆盖默认站点配置，启用 SPA 回退
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# 复制构建产物
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]


