#!/bin/bash

echo "🚀 Docker MCP Gateway Demo Setup"
echo "================================="

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not available. Please update Docker Desktop."
    exit 1
fi

echo "✅ Docker and Docker Compose are available"

# Create project structure
echo "📁 Creating project structure..."
mkdir -p weather-server scripts

# Create weather server files
echo "📝 Creating weather server files..."

cat > weather-server/package.json << 'EOF'
{
  "name": "weather-server",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^0.5.0"
  }
}
EOF

cat > weather-server/index.js << 'EOF'
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema, McpError, ErrorCode } from '@modelcontextprotocol/sdk/types.js';

const server = new Server({
  name: 'weather-server',
  version: '1.0.0',
  description: 'Simple weather MCP server'
}, {
  capabilities: { tools: {} },
});

// Mock weather data
const weatherData = {
  london: { temp: 15, condition: 'cloudy' },
  paris: { temp: 18, condition: 'sunny' },
  tokyo: { temp: 22, condition: 'rainy' },
  'new york': { temp: 12, condition: 'windy' },
};

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [{
    name: 'get_weather',
    description: 'Get weather for a city',
    inputSchema: {
      type: 'object',
      properties: { city: { type: 'string', description: 'City name' } },
      required: ['city'],
    },
  }],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === 'get_weather') {
    const city = args.city.toLowerCase();
    const weather = weatherData[city] || { temp: 20, condition: 'unknown' };
    return {
      content: [{
        type: 'text',
        text: `Weather in ${args.city}: ${weather.temp}°C, ${weather.condition}`,
      }],
    };
  }

  throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
});

async function main() {
  try {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error('Weather server running and awaiting MCP requests');
  } catch (error) {
    console.error('[ERROR] MCP server exiting with error:', error);
    process.exit(1);
  }
}

main();
EOF

cat > weather-server/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY index.js .
CMD ["node", "index.js"]
EOF

# Create catalog
echo "📋 Creating MCP catalog..."
cat > catalog.yaml << 'EOF'
registry:
  duckduckgo:
    description: A Model Context Protocol (MCP) server that provides web search capabilities through DuckDuckGo
    title: DuckDuckGo Search
    type: server
    image: mcp/duckduckgo@sha256:68eb20db6109f5c312a695fc5ec3386ad15d93ffb765a0b4eb1baf4328dec14f
    allowHosts:
      - html.duckduckgo.com:443
    tools:
      - name: search

  weather-server:
    description: "Simple weather MCP server providing mock weather data"
    title: "Weather Server"
    type: "server"
    image: "docker-mcpgw-demo1-weather-server:latest"
    tools:
      - name: "get_weather"
EOF

# Create Docker Compose
echo "🐋 Creating Docker Compose configuration..."
cat > compose.yaml << 'EOF'
services:
  gateway:
    image: docker/mcp-gateway
    ports:
      - "8811:8811"
    command:
      - --servers=duckduckgo,weather-server
      - --catalog=/mcp/catalog.yaml
      - --transport=sse
      - --port=8811
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./catalog.yaml:/mcp/catalog.yaml:ro
    environment:
      - DOCKER_MCP_LOG_LEVEL=info
EOF

# Build weather server
echo "🔨 Building weather server image..."
docker build -t docker-mcpgw-demo1-weather-server:latest ./weather-server/

if [ $? -eq 0 ]; then
    echo "✅ Weather server image built successfully"
else
    echo "❌ Failed to build weather server image"
    exit 1
fi

# Create test script
echo "🧪 Creating test script..."
cat > scripts/test.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Docker MCP Gateway"
echo "=============================="

# Wait for gateway to start
echo "⏳ Waiting for gateway to start..."
sleep 5

echo ""
echo "📋 Listing available tools:"
curl -s http://localhost:8811/tools/list | jq '.' 2>/dev/null || curl -s http://localhost:8811/tools/list

echo ""
echo "🌤️ Testing weather server (London):"
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "get_weather", "arguments": {"city": "London"}}' | jq '.' 2>/dev/null || \
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "get_weather", "arguments": {"city": "London"}}'

echo ""
echo "🌤️ Testing weather server (Tokyo):"
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "get_weather", "arguments": {"city": "Tokyo"}}' | jq '.' 2>/dev/null || \
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "get_weather", "arguments": {"city": "Tokyo"}}'

echo ""
echo "🔍 Testing DuckDuckGo search:"
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "search", "arguments": {"query": "Docker MCP Gateway"}}' | jq '.' 2>/dev/null || \
curl -s -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{"name": "search", "arguments": {"query": "Docker MCP Gateway"}}'

echo ""
echo "✅ Testing complete!"
echo ""
echo "💡 Gateway is running at: http://localhost:8811"
echo "💡 Use Ctrl+C to stop the gateway"
EOF

chmod +x scripts/test.sh

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 To start the demo:"
echo "   docker compose up"
echo ""
echo "🧪 To test (in another terminal):"
echo "   ./scripts/test.sh"
echo ""
echo "📖 See README.md for detailed documentation"