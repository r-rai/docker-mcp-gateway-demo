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