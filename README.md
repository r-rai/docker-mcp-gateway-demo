# Docker MCP Gateway Demo

A comprehensive demonstration of Docker MCP Gateway with multiple MCP servers including weather data and web search capabilities.

## 🏗️ Architecture

```
┌─────────────────┐    HTTP/SSE     ┌──────────────────────┐
│   AI Clients    │◄─── :8811 ────►│  Docker MCP Gateway  │
│                 │                 │                      │
│ • VS Code       │                 │ • Route requests     │
│ • Claude        │                 │ • Manage containers  │
│ • Cursor        │                 │ • Protocol handling  │
│ • Custom Apps   │                 │                      │
└─────────────────┘                 └──────────┬───────────┘
                                               │
                                               │ stdio/JSON-RPC
                                               ▼
                    ┌─────────────────────────────────────────────────┐
                    │           Container Orchestration               │
                    │                                                │
                    ▼                    ▼                    ▼      │
        ┌─────────────────────┐ ┌─────────────────────┐ ┌──────────────┐
        │   Weather Server    │ │  DuckDuckGo Server  │ │ Other Servers│
        │                     │ │                     │ │              │
        │ • Node.js           │ │ • Official Image    │ │ • Calculator │
        │ • Mock weather data │ │ • Web search        │ │ • File ops   │
        │ • get_weather tool  │ │ • search tool       │ │ • Custom     │
        └─────────────────────┘ └─────────────────────┘ └──────────────┘
```

## 🚀 Prerequisites

### System Requirements
- **Docker Desktop**: Latest version with Docker Compose
- **Docker MCP CLI**: Docker's MCP command-line interface
- **Operating System**: Linux, macOS, or Windows with WSL2

### Install Docker MCP Gateway

1. **Install Docker MCP CLI:**
   ```bash
# Clone the repository
git clone https://github.com/docker/mcp-gateway.git
cd mcp-gateway
mkdir -p "$HOME/.docker/cli-plugins/"

# Build and install the plugin
make docker-mcp
   ```

2. **Verify Installation:**
   ```bash
   docker mcp version
   docker mcp --help
   ```

## 📁 Project Structure

```
docker-mcp-demo/
├── README.md
├── compose.yaml                 # Docker Compose configuration
├── catalog.yaml                 # MCP server catalog
├── weather-server/
│   ├── Dockerfile
│   ├── package.json
│   └── index.js                 # Weather server implementation
└── scripts/
    ├── setup.sh                 # Setup script
    └── test.sh                  # Testing script
```

## 🛠️ Setup Instructions

### 1. Clone or Create Project Structure

## 🚀 Running the Demo

### 1. Build Weather Server Image

```bash
# Build the weather server
docker build -t docker-mcpgw-demo1-weather-server:latest ./weather-server/
```

### 2. Start the Gateway

```bash
# Start the MCP Gateway and servers
docker compose up
```

You should see output like:
```
gateway-1  | - Those servers are enabled: duckduckgo, weather-server
gateway-1  | - weather-server: Weather server running and awaiting MCP requests
gateway-1  |   > weather-server: (1 tools)
gateway-1  |   > duckduckgo: (2 tools)
gateway-1  | > 3 tools listed in 2.5s
gateway-1  | > Start sse server on port 8811
```

## 🧪 Testing the Setup

### Using cURL

**Test Weather Server:**
```bash
curl -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "name": "get_weather",
    "arguments": {"city": "London"}
  }'
```

**Test DuckDuckGo Search:**
```bash
curl -X POST http://localhost:8811/tools/call \
  -H "Content-Type: application/json" \
  -d '{
    "name": "search", 
    "arguments": {"query": "Docker MCP Gateway"}
  }'
```

**List All Available Tools:**
```bash
curl http://localhost:8811/tools/list
```

### Using Docker MCP CLI (if available)

```bash
# List tools
docker mcp tools list --gateway http://localhost:8811

# Call weather tool
docker mcp tools call get_weather '{"city": "Paris"}' --gateway http://localhost:8811

# Call search tool
docker mcp tools call search '{"query": "MCP protocol"}' --gateway http://localhost:8811
```

## 🔌 Client Integration

### VS Code MCP Extension

Add to your VS Code settings:
```json
{
  "mcp.servers": {
    "docker-gateway": {
      "transport": "sse",
      "url": "http://localhost:8811/sse"
    }
  }
}
```

### Claude Desktop

Add to `~/.claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "docker-gateway": {
      "command": "curl",
      "args": [
        "-X", "POST",
        "http://localhost:8811/tools/call",
        "-H", "Content-Type: application/json",
        "-d", "@-"
      ]
    }
  }
}
```

### Custom Applications

**JavaScript/Node.js Example:**
```javascript
async function callMCPTool(toolName, arguments) {
  const response = await fetch('http://localhost:8811/tools/call', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: toolName, arguments })
  });
  return await response.json();
}

// Usage
const weather = await callMCPTool('get_weather', { city: 'Tokyo' });
const search = await callMCPTool('search', { query: 'Docker containers' });
```

**Python Example:**
```python
import requests

def call_mcp_tool(tool_name, arguments):
    response = requests.post(
        'http://localhost:8811/tools/call',
        json={'name': tool_name, 'arguments': arguments}
    )
    return response.json()

# Usage
weather = call_mcp_tool('get_weather', {'city': 'London'})
search = call_mcp_tool('search', {'query': 'MCP protocol'})
```

## 🔧 Configuration Options

### Gateway Command Options

- `--port`: Server port (default: 8080)
- `--transport`: Transport type (`sse`, `streaming`)
- `--servers`: Comma-separated list of enabled servers
- `--catalog`: Path to catalog file
- `--timeout`: Request timeout

### Environment Variables

- `DOCKER_MCP_LOG_LEVEL`: Log level (`debug`, `info`, `warn`, `error`)
- `DOCKER_MCP_MEMORY_LIMIT`: Memory limit for server containers
- `DOCKER_MCP_CPU_LIMIT`: CPU limit for server containers

## 🚨 Troubleshooting

### Common Issues

**1. Server Not Found in Catalog**
```bash
# Check catalog loading
docker compose logs gateway

# Verify image exists
docker images | grep weather-server
```

**2. Connection Issues**
```bash
# Check if gateway is running
curl http://localhost:8811/health

# Check Docker socket permissions
ls -la /var/run/docker.sock
```

**3. Tool Call Failures**
```bash
# Check server logs
docker compose logs gateway | grep weather-server

# Test individual server
docker run -it --rm docker-mcpgw-demo1-weather-server:latest
```

### Debug Mode

Enable debug logging:
```yaml
environment:
  - DOCKER_MCP_LOG_LEVEL=debug
```

### Server Status

Check which servers are enabled:
```bash
curl http://localhost:8811/servers/list
```

## 📊 Performance Considerations

### Resource Limits

- Each server container is limited to 1 CPU and 2GB RAM by default
- Containers are created on-demand and destroyed after use
- Gateway maintains connection pools for frequently used servers

### Scaling

- Multiple gateway instances can run on different ports
- Load balancing can be implemented using reverse proxies
- Server containers can be pre-warmed for better performance

## 🔒 Security

### Container Security

- Servers run with `--security-opt no-new-privileges`
- Non-root users are created in server containers
- Network isolation between server containers
- Read-only filesystem mounts where possible

### Access Control

- Gateway exposes HTTP endpoints - consider authentication
- Docker socket access required - run gateway in secure environment
- Server containers have limited resource access

## 🎯 Next Steps

### Adding New Servers

1. Create new server directory with Dockerfile and code
2. Build server image
3. Add entry to `catalog.yaml`
4. Update `compose.yaml` to include new server
5. Rebuild and restart

### Production Deployment

1. Use proper secrets management
2. Implement authentication and authorization
3. Set up monitoring and logging
4. Configure resource limits appropriately
5. Use container orchestration (Kubernetes, Docker Swarm)

## 📚 Additional Resources

- [Docker MCP Gateway Documentation](https://docs.docker.com/mcp/)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/sdk)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**🎉 Happy Building with Docker MCP Gateway!**
