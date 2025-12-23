# Trino Local Setup with Iceberg & S3

A Docker-based Trino server configured for Apache Iceberg tables with S3-compatible storage.

## Prerequisites

- Docker and Docker Compose
- [Just](https://github.com/casey/just) command runner
- S3-compatible storage (MinIO, AWS S3, etc.)

## Quick Start

```bash
# 1. Create configuration
just setup

# 2. Edit .env with your S3 credentials
nano .env

# 3. Start Trino
just up

# 4. Access CLI
just cli
```

Trino Web UI: http://localhost:8081

## Configuration

### Environment Variables (.env)

```env
S3_ENDPOINT=http://your-s3-endpoint:9000
S3_ACCESS_KEY=your-access-key
S3_SECRET_KEY=your-secret-key
S3_PATH_STYLE_ACCESS=true
AWS_REGION=us-east-1
```

### Authentication (Optional)

You can enable password authentication by setting these variables in `.env`:

```env
TRINO_AUTHENTICATION_TYPE=PASSWORD
TRINO_PASSWORD=your-secure-password
```

If not set, authentication is disabled (default).

### Memory Settings

Edit `etc/jvm.config` to adjust heap size (default: 4GB):
```
-Xmx4G
```

## Available Commands

Run `just` to see all available commands, or use these common ones:

```bash
just setup         # Create .env file
just up            # Start Trino server
just down          # Stop Trino server
just restart       # Restart server
just status        # Show service status
just logs          # View logs
just cli           # Access Trino CLI
just health        # Check health
just web           # Open Web UI
just clean         # Clean up volumes
just validate      # Validate configuration
just test          # Run test suite
just query "SQL"   # Execute SQL query
```

## Working with Iceberg Tables

### Create a Schema
```sql
CREATE SCHEMA iceberg.my_schema;
```

### Create a Table
```sql
CREATE TABLE iceberg.my_schema.events (
    id BIGINT,
    name VARCHAR,
    timestamp TIMESTAMP
) WITH (
    format = 'PARQUET',
    location = 's3a://my-bucket/events'
);
```

### Insert Data
```sql
INSERT INTO iceberg.my_schema.events VALUES
    (1, 'event1', CURRENT_TIMESTAMP),
    (2, 'event2', CURRENT_TIMESTAMP);
```

### Query Data
```sql
SELECT * FROM iceberg.my_schema.events;
```

### Iceberg Features

**Time Travel:**
```sql
SELECT * FROM iceberg.my_schema.events 
FOR VERSION AS OF 1234567890;
```

**Table Optimization:**
```sql
ALTER TABLE iceberg.my_schema.events EXECUTE optimize;
```

**View Metadata:**
```sql
SELECT * FROM iceberg.my_schema."events$snapshots";
SELECT * FROM iceberg.my_schema."events$files";
SELECT * FROM iceberg.my_schema."events$history";
```

## Examples

See `examples/sample-queries.sql` for more SQL examples.

To run the examples:
```bash
# Edit examples/sample-queries.sql and replace 'my-bucket' with your bucket
docker exec -it trino-server trino --server localhost:8081 < examples/sample-queries.sql
```

## Troubleshooting

### Trino won't start
```bash
just logs       # Check logs
just validate   # Validate config
```

### S3 connection issues
- Verify S3 endpoint is accessible
- Check credentials in `.env`
- Ensure bucket exists

### Out of memory
- Increase heap size in `etc/jvm.config`
- Adjust query memory in `etc/config.properties`

### Reset everything
```bash
just clean
just setup
# Edit .env
just up
```

## Directory Structure

```
.
├── docker-compose.yml      # Docker configuration
├── justfile               # Command shortcuts
├── .env                   # Your S3 credentials (create from .env.example)
├── etc/                   # Trino configuration
│   ├── config.properties  # Server settings
│   ├── jvm.config        # JVM/memory settings
│   └── node.properties   # Node settings
├── catalog/              # Catalog configuration
│   └── iceberg.properties # Iceberg & S3 settings
└── examples/             # SQL examples
    └── sample-queries.sql
```

## Production Notes

This setup is for **local development**. For production:

- Use proper Hive Metastore or AWS Glue (not file-based)
- Configure authentication (LDAP, OAuth)
- Enable TLS/SSL
- Use multiple worker nodes
- Set up monitoring (Prometheus, Grafana)
- Use managed S3 (AWS S3)
- Implement backup strategy

## Resources

- [Trino Documentation](https://trino.io/docs/current/)
- [Iceberg Documentation](https://iceberg.apache.org/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
