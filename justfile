# Trino Local Development

# Show available commands
default:
    @just --list

# Create .env file from template
setup:
    #!/usr/bin/env bash
    if [ ! -f .env ]; then
        echo "Creating .env file from template..."
        cp .env.example .env
        echo "✓ .env created. Please edit it with your S3 credentials."
    else
        echo "✓ .env already exists"
    fi

# Start Trino server
up:
    @echo "Starting Trino server..."
    @if grep -q "COMPOSE_PROFILES=local-db" .env 2>/dev/null || [ -z "$(grep POSTGRES_URL .env 2>/dev/null)" ]; then \
        docker-compose --profile local-db up -d; \
    else \
        docker-compose up -d; \
    fi
    @echo "✓ Trino started at http://localhost:8081"

# Start Trino with logs
up-logs:
    @if grep -q "COMPOSE_PROFILES=local-db" .env 2>/dev/null || [ -z "$(grep POSTGRES_URL .env 2>/dev/null)" ]; then \
        docker-compose --profile local-db up; \
    else \
        docker-compose up; \
    fi

# Stop Trino server
down:
    @echo "Stopping Trino server..."
    @docker-compose down
    @echo "✓ Trino stopped"

# Restart Trino server
restart: down up

# Show service status
status:
    @docker-compose ps

# View logs
logs:
    @docker-compose logs -f trino

# Access Trino CLI
cli:
    @docker exec -it trino-server trino --server localhost:8081

# Check Trino health
health:
    @curl -sf http://localhost:8081/v1/info | jq '.' || echo "✗ Trino not responding"

# Open Web UI in browser
web:
    @command -v xdg-open >/dev/null && xdg-open http://localhost:8081 || \
     command -v open >/dev/null && open http://localhost:8081 || \
     echo "Open http://localhost:8081 in your browser"

# Stop and remove volumes
clean:
    @echo "Cleaning up..."
    @docker-compose down -v
    @echo "✓ Cleanup complete"

# Validate environment configuration
validate:
    #!/usr/bin/env bash
    if [ ! -f .env ]; then
        echo "✗ .env not found. Run 'just setup' first."
        exit 1
    fi
    echo "✓ .env exists"
    source .env
    [ -z "$S3_ENDPOINT" ] && echo "✗ S3_ENDPOINT not set" || echo "✓ S3_ENDPOINT set"
    [ -z "$S3_ACCESS_KEY" ] && echo "✗ S3_ACCESS_KEY not set" || echo "✓ S3_ACCESS_KEY set"
    [ -z "$S3_SECRET_KEY" ] && echo "✗ S3_SECRET_KEY not set" || echo "✓ S3_SECRET_KEY set"

# Run test suite
test:
    @./test-setup.sh

# Execute a SQL query
query QUERY:
    @docker exec -it trino-server trino --server localhost:8081 --execute "{{QUERY}}"

# Execute SQL from a file
query-file FILE:
    @docker exec -i trino-server trino --server localhost:8081 < {{FILE}}

# Show Iceberg schemas
show-schemas:
    @just query "SHOW SCHEMAS FROM iceberg"

# Show tables in a schema
show-tables SCHEMA:
    @just query "SHOW TABLES FROM iceberg.{{SCHEMA}}"

# Pull latest Trino image
pull:
    @docker-compose pull

# Update to latest Trino version
update: pull restart
