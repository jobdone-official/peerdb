#!/bin/sh
set -Eeu

# JobDone PeerDB Launcher
# Compatible with run-peerdb.sh style
# Uses external PostgreSQL with custom passwords

# Support podman like run-peerdb.sh
DOCKER="docker"
if test -n "${USE_PODMAN:=}"; then
    if ! (command -v docker &> /dev/null); then
        if (command -v podman &> /dev/null); then
            echo "docker could not be found on PATH, using podman"
            USE_PODMAN=1
        else
            echo "docker could not be found on PATH"
            exit 1
        fi
    fi
fi

if test -n "$USE_PODMAN"; then
    DOCKER="podman"
fi

# Check Docker/Podman access
if ! $DOCKER ps >/dev/null 2>&1; then
    echo "Error: Cannot access Docker daemon. Permission denied."
    echo ""
    echo "To fix this, either:"
    echo "1. Add your user to the docker group:"
    echo "   sudo usermod -aG docker \$USER"
    echo "   newgrp docker"
    echo ""
    echo "2. Or run with sudo:"
    echo "   sudo ./jobdone.sh up"
    echo ""
    exit 1
fi

# Check if .env.jobdone exists
if [ ! -f .env.jobdone ]; then
    echo "Error: .env.jobdone not found!"
    echo "Please create it by copying the template:"
    echo "  cp .env.jobdone.template .env.jobdone"
    echo "Then edit .env.jobdone with your PostgreSQL connection details"
    exit 1
fi

# Load environment variables
set -a
. ./.env.jobdone
set +a

# Validate required variables
if [ -z "$PEERDB_CATALOG_HOST" ] || [ "$PEERDB_CATALOG_HOST" = "your-postgres-host.example.com" ]; then
    echo "Error: Please configure PEERDB_CATALOG_HOST in .env.jobdone"
    exit 1
fi

# Command handling
case "${1:-up}" in
    up|start)
        echo "Starting PeerDB with external PostgreSQL..."
        echo "PostgreSQL: $PEERDB_CATALOG_HOST:$PEERDB_CATALOG_PORT/$PEERDB_CATALOG_DATABASE"
        $DOCKER compose pull
        # Note: docker-compose.override.yml is automatically loaded
        if [ "${2:-}" = "-d" ]; then
            exec $DOCKER compose up -d
        else
            exec $DOCKER compose up --no-attach temporal --no-attach temporal-ui --no-attach temporal-admin-tools
        fi
        ;;
    
    up-all)
        echo "Starting all PeerDB services..."
        $DOCKER compose pull
        exec $DOCKER compose up
        ;;
    
    down|stop)
        echo "Stopping PeerDB..."
        $DOCKER compose down
        ;;
    
    logs)
        shift
        $DOCKER compose logs "$@"
        ;;
    
    ps)
        $DOCKER compose ps
        ;;
    
    *)
        echo "Usage: $0 {up|up-all|down|logs|ps} [options]"
        echo "  up      - Start with minimal output (like run-peerdb.sh)"
        echo "  up-all  - Start with all service output"
        echo "  down    - Stop all services"
        echo "  logs    - View logs"
        echo "  ps      - Show status"
        ;;
esac