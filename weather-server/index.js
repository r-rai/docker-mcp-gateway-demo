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
  } // <-- FIXED: Missing closing brace

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
} // <-- FIXED: Missing closing brace

main();
