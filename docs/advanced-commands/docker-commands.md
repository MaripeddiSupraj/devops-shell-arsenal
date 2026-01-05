# Docker Command Mastery for DevOps

Essential Docker commands and patterns for container operations in production.

---

## Docker Basics (The Right Way)

### Container Lifecycle

```bash
# Run container
docker run -d --name web nginx

# Run with port mapping
docker run -d -p 8080:80 nginx

# Run with environment variables
docker run -d -e DB_HOST=postgres -e DB_PORT=5432 myapp

# Run with volume mount
docker run -d -v /data:/app/data myapp

# Run with auto-remove
docker run --rm alpine echo "Hello"

# Run interactively
docker run -it ubuntu bash

# Run with resource limits
docker run -d --memory="512m" --cpus="1.5" nginx
```

### Container Management

```bash
# List running containers
docker ps

# List all (including stopped)
docker ps -a

# Stop container
docker stop web

# Start stopped container
docker start web

# Restart container
docker restart web

# Remove container
docker rm web

# Force remove running container
docker rm -f web

# Remove all stopped containers
docker container prune
```

---

## Real-World Docker Operations

### 1. Debug Running Container

```bash
# View logs
docker logs web

# Follow logs
docker logs -f web

# Last 100 lines
docker logs --tail 100 web

# Logs since timestamp
docker logs --since 2026-01-05T10:00:00 web

# Execute command in running container
docker exec -it web bash

# Run command as specific user
docker exec -it -u root web bash

# Copy files from container
docker cp web:/app/config.json ./

# Copy files to container
docker cp ./file.txt web:/app/
```

### 2. Inspect Container

```bash
# Full inspect (JSON)
docker inspect web

# Get specific field
docker inspect web --format='{{.State.Status}}'

# Get IP address
docker inspect web --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# Get environment variables
docker inspect web --format='{{range .Config.Env}}{{println .}}{{end}}'

# Show container stats
docker stats web

# Show all container stats
docker stats
```

### 3. Clean Up Docker

```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused data (aggressive!)
docker system prune

# Show disk usage
docker system df

# Remove dangling images
docker rmi $(docker images -f "dangling=true" -q)

# Remove exited containers
docker rm $(docker ps -aq -f status=exited)

# Remove old images (keep recent)
docker image prune -a --filter "until=720h"
```

---

## Docker Images

### Building Images

```bash
# Build from Dockerfile
docker build -t myapp:1.0 .

# Build with build args
docker build --build-arg VERSION=1.0 -t myapp .

# Build without cache
docker build --no-cache -t myapp .

# Build with specific Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Tag image
docker tag myapp:1.0 myapp:latest
docker tag myapp:1.0 registry.com/myapp:1.0
```

### Image Management

```bash
# List images
docker images

# Remove image
docker rmi myapp:1.0

# Pull image
docker pull nginx:alpine

# Push to registry
docker push registry.com/myapp:1.0

# Save image to tar
docker save myapp:1. > myapp.tar

# Load image from tar
docker load < myapp.tar

# Show image history (layers)
docker history myapp:1.0

# Inspect image
docker inspect myapp:1.0
```

---

## Docker Networking

### Network Operations

```bash
# List networks
docker network ls

# Create network
docker network create mynet

# Connect container to network
docker network connect mynet web

# Disconnect
docker network disconnect mynet web

# Inspect network
docker network inspect mynet

# Run container on specific network
docker run -d --network mynet --name web nginx
```

### Container Communication

```bash
# Create network
docker network create app-network

# Run database
docker run -d --network app-network --name db postgres

# Run app (can connect via hostname "db")
docker run -d --network app-network --name app myapp

# Test connectivity
docker exec app ping db
```

---

## Docker Volumes

### Volume Management

```bash
# List volumes
docker volume ls

# Create volume
docker volume create mydata

# Use volume
docker run -d -v mydata:/app/data myapp

# Bind mount (host directory)
docker run -d -v /host/path:/container/path myapp

# Read-only mount
docker run -d -v /host/path:/container/path:ro myapp

# Remove volume
docker volume rm mydata

# Remove unused volumes
docker volume prune

# Inspect volume
docker volume inspect mydata
```

---

## Production Patterns

### 1. Health Checks

```bash
# Run with health check
docker run -d \
  --health-cmd='curl -f http://localhost/health || exit 1' \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  myapp

# Check health status
docker inspect --format='{{.State.Health.Status}}' myapp
```

### 2. Restart Policies

```bash
# Always restart
docker run -d --restart=always nginx

# Restart unless stopped
docker run -d --restart=unless-stopped nginx

# Restart on failure (max 3 times)
docker run -d --restart=on-failure:3 myapp

# Update restart policy
docker update --restart=always mycontainer
```

### 3. Resource Limits

```bash
# Memory limit
docker run -d --memory="512m" --memory-swap="1g" myapp

# CPU limit
docker run -d --cpus="1.5" myapp

# CPU shares (relative weight)
docker run -d --cpu-shares=512 myapp

# Update limits on running container
docker update --memory="1g" --cpus="2" mycontainer
```

### 4. Log Management

```bash
# Limit log size
docker run -d \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp

# JSON file logging
docker run -d --log-driver json-file myapp

# Syslog logging
docker run -d --log-driver syslog myapp

# Send to remote syslog
docker run -d \
  --log-driver syslog \
  --log-opt syslog-address=tcp://192.168.1.100:514 \
  myapp
```

---

## Docker Compose Quick Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart service
docker-compose restart web

# Build images
docker-compose build

# Scale service
docker-compose up -d --scale web=3

# Execute command
docker-compose exec web bash

# Show running services
docker-compose ps
```

---

## Troubleshooting

### Container Won't Start?

```bash
# Check logs
docker logs container-name

# Run interactively to debug
docker run -it --entrypoint=/bin/bash myapp

# Check docker daemon
sudo systemctl status docker
journalctl -u docker -f
```

### Out of Disk Space?

```bash
# Check usage
docker system df

# Clean everything
docker system prune -a --volumes

# Remove specific items
docker container prune
docker image prune -a
docker volume prune
```

### Network Issues?

```bash
# Inspect network
docker network inspect bridge

# Check DNS
docker exec container cat /etc/resolv.conf

# Test connectivity
docker exec container ping google.com
```

---

## Useful One-Liners

```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)

# Remove dangling volumes
docker volume rm $(docker volume ls -qf dangling=true)

# Get container IP
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container

# Show port mappings
docker port container

# Copy file from all containers
for c in $(docker ps -q); do docker cp $c:/app/log.txt $(docker inspect --format='{{.Name}}' $c).txt; done
```

---

## Cheat Sheet

```bash
# Container lifecycle
docker run -d myapp                  # Run detached
docker ps                            # List running
docker ps -a                         # List all
docker stop container                # Stop
docker start container               # Start
docker restart container             # Restart
docker rm container                  # Remove
docker logs -f container             # View logs
docker exec -it container bash       # Shell into container

# Images
docker build -t name:tag .           # Build
docker images                        # List
docker rmi image                     # Remove
docker pull image                    # Download
docker push image                    # Upload

# Cleanup
docker system prune                  # Clean all
docker container prune               # Clean containers
docker image prune                   # Clean images
docker volume prune                  # Clean volumes

# Info
docker inspect container             # Full info
docker stats                         # Resource usage
docker logs container                # Logs
docker top container                 # Processes
```

---

**Master Docker for efficient container operations!** 🐳
