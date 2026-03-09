FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

ARG VITE_BASE_URL
ARG VITE_API_URL
ARG VITE_BASE_PATH
ARG VITE_OUT_DIR

ENV VITE_BASE_URL=${VITE_BASE_URL}
ENV VITE_API_URL=${VITE_API_URL}
ENV VITE_BASE_PATH=${VITE_BASE_PATH}

RUN pnpm run build:prod


FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist-platform /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
