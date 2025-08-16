# JobDone PeerDB Setup

This setup allows you to run PeerDB with your own external PostgreSQL database while maintaining easy updates from upstream.

## Files Included

- `docker-compose.override.yml` - Overrides default settings to use external PostgreSQL
- `.env.jobdone.template` - Template for your configuration (copy this to `.env.jobdone`)
- `jobdone.sh` - Simple startup script
- `.gitignore` - Configured to ignore `.env.jobdone` with your secrets

## Prerequisites

- Docker or Podman installed
- Access to Docker daemon (user must be in `docker` group or have sudo access)
- External PostgreSQL database

### Docker Permission Setup

If you get a "permission denied" error when accessing Docker:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply the group change (or logout and login again)
newgrp docker

# Verify Docker access
docker ps
```

Alternatively, you can run with sudo:
```bash
sudo ./jobdone.sh up
```

## Setup Instructions

1. **Copy the template and configure your PostgreSQL connection**:
   ```bash
   cp .env.jobdone.template .env.jobdone
   ```
   
   Then edit `.env.jobdone`:
   ```bash
   PEERDB_CATALOG_HOST=your-postgres-host.example.com
   PEERDB_CATALOG_PORT=5432
   PEERDB_CATALOG_USER=peerdb_user
   PEERDB_CATALOG_PASSWORD=your-secure-password
   PEERDB_CATALOG_DATABASE=peerdb
   ```

2. **Change all default passwords** in `.env.jobdone`:
   - `PEERDB_PASSWORD` - PeerDB server password
   - `NEXTAUTH_SECRET` - Generate with: `openssl rand -base64 32`
   - `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` - MinIO admin credentials

3. **Initialize your PostgreSQL database**:
   Your external PostgreSQL needs the PeerDB schema. Check `volumes/docker-entrypoint-initdb.d/` for SQL scripts to run.

## Usage

```bash
# Start PeerDB
./jobdone.sh up
./jobdone.sh up -d  # Run in background

# Stop PeerDB
./jobdone.sh down

# View logs
./jobdone.sh logs
./jobdone.sh logs -f flow-api  # Follow specific service
./jobdone.sh logs -f --since=1m  # Show logs from last minute

# Check status
./jobdone.sh ps
```

## Access Points

- **PeerDB UI**: http://localhost:3000
- **PeerDB Server**: localhost:9900 (SQL interface)
- **Temporal UI**: http://localhost:8085
- **MinIO Console**: http://localhost:9002

## Updating from Upstream

Your custom files won't conflict with upstream:
```bash
git pull origin main
# Your settings remain untouched!
```

## How It Works

1. Docker Compose automatically loads both `docker-compose.yml` and `docker-compose.override.yml`
2. The override file:
   - Disables the local PostgreSQL catalog service
   - Points all services to your external PostgreSQL
   - Uses your custom passwords from `.env.jobdone`
3. All your custom files are git-ignored

## Troubleshooting

- **Connection refused**: Ensure your PostgreSQL is accessible from Docker containers
- **Authentication failed**: Check credentials in `.env.jobdone`
- **Missing tables**: Run the initialization SQL from `volumes/docker-entrypoint-initdb.d/`

## Notes

- The local catalog service is disabled (uses `profiles: ["disabled"]`)
- Temporal stores its data in your external PostgreSQL
- MinIO still runs locally for S3-compatible storage (unless you configure AWS/GCS)