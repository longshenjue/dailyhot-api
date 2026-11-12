FROM node:22-alpine AS builder
WORKDIR /app
RUN npm install --global pnpm@10
COPY package.json pnpm-lock.yaml tsconfig.json LICENSE ./
RUN pnpm install --frozen-lockfile
COPY src ./src
COPY public ./public
RUN pnpm build && pnpm prune --prod

FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=docker PORT=6688 USE_LOG_FILE=false REDIS_ENABLED=false
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 hono && mkdir -p /app/logs && chown hono:nodejs /app/logs
COPY --from=builder --chown=hono:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=hono:nodejs /app/dist ./dist
COPY --from=builder --chown=hono:nodejs /app/public ./public
COPY --from=builder --chown=hono:nodejs /app/package.json ./package.json
COPY --from=builder --chown=hono:nodejs /app/LICENSE ./LICENSE
USER hono:nodejs
EXPOSE 6688
CMD ["node", "dist/index.js"]
