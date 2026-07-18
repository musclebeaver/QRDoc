# 1단계: 빌드 스테이지
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# 2단계: 실행 스테이지
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder /app/dist ./dist
# .env 파일은 docker-compose에서 주입하므로 COPY하지 않음

ENV PORT=3000
EXPOSE 3000

CMD ["node", "dist/app.js"]
