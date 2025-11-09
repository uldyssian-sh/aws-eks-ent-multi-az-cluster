#!/bin/bash

set -e

echo "🛠️ Setting up development environment"

# Install pre-commit hooks
if command -v pre-commit &> /dev/null; then
    echo "📋 Installing pre-commit hooks..."
    pre-commit install
else
    echo "⚠️ pre-commit not found. Install with: pip install pre-commit"
fi

# Setup local monitoring stack
echo "📊 Starting local monitoring stack..."
docker-compose up -d

# Wait for services
echo "⏳ Waiting for services to start..."
sleep 30

# Verify services
echo "✅ Verifying services..."
curl -f http://localhost:9090/-/healthy || echo "❌ Prometheus not ready"
curl -f http://localhost:3000/api/health || echo "❌ Grafana not ready"
curl -f http://localhost:16686/ || echo "❌ Jaeger not ready"

echo "🎉 Development environment ready!"
echo "📊 Prometheus: http://localhost:9090"
echo "📈 Grafana: http://localhost:3000 (admin/admin123)"
echo "🔍 Jaeger: http://localhost:16686"# Updated Sun Nov  9 12:50:06 CET 2025
# Updated Sun Nov  9 12:52:18 CET 2025
