FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY index.js .
# Proper MCP server startup - no background process needed
CMD ["node", "index.js"]
