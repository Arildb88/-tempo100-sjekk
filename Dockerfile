FROM node:22-alpine
WORKDIR /app
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src
COPY --chown=node:node public ./public
ENV HOST=0.0.0.0 PORT=3000 DATA_MODE=demo
USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
