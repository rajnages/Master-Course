# Docker Professional Handbook

## Table of Contents
1. Core Concepts
2. Installation & Setup
3. Working with Containers
4. Image Management
5. Networking
6. Storage & Volumes
7. Docker Compose
8. Production Deployment
9. Security
10. Performance & Optimization

## 1. Core Concepts

### 1.1 What is Docker?
Docker is a platform for developing, shipping, and running applications in containers. Key benefits:
- Consistent environments
- Lightweight resource utilization
- Rapid deployment
- Application isolation

### 1.2 Architecture
```plaintext
┌─────────────────────────────────────────────────────┐
│                  Docker Architecture                 │
│                                                     │
│ ┌─────────────┐ ┌─────────────┐    ┌─────────────┐ │
│ │   Docker    │ │   Docker    │    │   Docker    │ │
│ │   Client    │ │   Daemon    │    │  Registry   │ │
│ └─────────────┘ └─────────────┘    └─────────────┘ │
│       │               │                   │         │
│       └───────────────┴───────────────────┘         │
└─────────────────────────────────────────────────────┘
```

### 1.3 Key Components
- Docker Engine
- Docker Client
- Docker Daemon
- Docker Registry
- Docker Objects (images, containers, networks, volumes)

## 2. Installation & Setup

### 2.1 Installation Commands
```bash
# Ubuntu
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Post-installation steps
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

### 2.2 Configuration
```bash
# Docker daemon configuration (/etc/docker/daemon.json)
{
  "debug": true,
  "experimental": false,
  "registry-mirrors": ["https://mirror.gcr.io"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

## 3. Working with Containers

### 3.1 Basic Container Operations
```bash
# Run container
docker run -d \
    --name myapp \
    -p 8080:80 \
    -v /host/path:/container/path \
    -e ENV_VAR=value \
    --network my-network \
    image:tag

# Container lifecycle
docker start/stop/restart container_name
docker pause/unpause container_name
docker rm -f container_name
```

### 3.2 Container Inspection
```bash
# Detailed container info
docker inspect container_name

# Resource usage
docker stats container_name

# Process list
docker top container_name

# Port mappings
docker port container_name
```

## 4. Image Management

### 4.1 Dockerfile Best Practices
```dockerfile
# Multi-stage build example
FROM node:16-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 4.2 Image Operations
```bash
# Build with BuildKit
DOCKER_BUILDKIT=1 docker build \
    --build-arg VERSION=1.0 \
    --tag myapp:1.0 \
    --target prod \
    --network=host \
    .

# Image management
docker image prune -a --filter "until=24h"
docker save myapp:1.0 | gzip > myapp.tar.gz
docker load < myapp.tar.gz
```

## 5. Networking

### 5.1 Network Types
```bash
# Create custom network
docker network create \
    --driver overlay \
    --subnet 10.0.0.0/24 \
    --gateway 10.0.0.1 \
    my-network

# Network operations
docker network connect my-network container_name
docker network disconnect my-network container_name
```

### 5.2 Network Troubleshooting
```bash
# Network debugging container
docker run -it --rm \
    --network container:target_container \
    nicolaka/netshoot \
    tcpdump -i any

# DNS troubleshooting
docker run --rm \
    --network container:target_container \
    alpine nslookup service_name
```

## 6. Storage & Volumes

### 6.1 Volume Management
```bash
# Create and manage volumes
docker volume create --driver local \
    --opt type=nfs \
    --opt o=addr=192.168.1.1,rw \
    --opt device=:/path/to/dir \
    my-volume

# Backup volume
docker run --rm \
    --volumes-from source_container \
    -v $(pwd):/backup \
    alpine tar cvf /backup/backup.tar /data
```

### 6.2 Storage Drivers
```bash
# Check storage driver
docker info | grep "Storage Driver"

# Configure storage driver
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
```

## 7. Docker Compose

### 7.1 Docker Compose File Structure
```yaml
version: "3.9"

services:
  webapp:
    build: 
      context: ./webapp
      dockerfile: Dockerfile.prod
      args:
        - BUILD_ENV=production
    ports:
      - "80:80"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
    depends_on:
      db:
        condition: service_healthy
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.50'
          memory: 512M

  db:
    image: postgres:13-alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### 7.2 Advanced Compose Features
```bash
# Development vs Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Scaling services
docker-compose up -d --scale webapp=3

# View logs
docker-compose logs -f --tail=100 webapp

# Resource management
docker-compose top
```

## 8. Production Deployment

### 8.1 Container Orchestration
```bash
# Docker Swarm Initialization
docker swarm init --advertise-addr <MANAGER-IP>

# Deploy stack
docker stack deploy -c docker-compose.yml myapp

# Service management
docker service ls
docker service logs -f myapp_webapp
docker service scale myapp_webapp=5
```

### 8.2 High Availability Setup
```bash
# Add manager nodes
docker swarm join-token manager

# Configure service constraints
docker service create \
    --name webapp \
    --replicas 3 \
    --constraint 'node.role==worker' \
    --update-delay 10s \
    --update-parallelism 1 \
    --update-failure-action rollback \
    myapp:latest

# Health monitoring
docker service update \
    --health-cmd "curl -f http://localhost/health || exit 1" \
    --health-interval 5s \
    --health-retries 3 \
    --health-timeout 2s \
    webapp
```

## 9. Security

### 9.1 Container Security
```bash
# Security scanning
docker scan myapp:latest

# Run container with security options
docker run -d \
    --name secure_app \
    --security-opt no-new-privileges \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --read-only \
    --tmpfs /tmp \
    myapp:latest

# Content trust
export DOCKER_CONTENT_TRUST=1
docker push myapp:latest
```

### 9.2 Network Security
```bash
# Create encrypted overlay network
docker network create \
    --driver overlay \
    --opt encrypted \
    --attachable \
    secure_network

# Configure network policies
{
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "userland-proxy": false
}
```

## 10. Performance & Optimization

### 10.1 Resource Monitoring
```bash
# Advanced monitoring setup
docker run -d \
    --name prometheus \
    -p 9090:9090 \
    -v prometheus_data:/prometheus \
    prom/prometheus

# Grafana dashboard
docker run -d \
    --name grafana \
    -p 3000:3000 \
    -v grafana_data:/var/lib/grafana \
    grafana/grafana
```

### 10.2 Performance Tuning
```bash
# Container resource limits
docker run -d \
    --name optimized_app \
    --cpus 2 \
    --memory 2g \
    --memory-reservation 1g \
    --kernel-memory 500m \
    --pids-limit 100 \
    myapp:latest

# System tuning
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 10
}
```

### 10.3 Logging Best Practices
```bash
# Configure logging drivers
docker run -d \
    --name app_with_logging \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    --log-opt compress=true \
    myapp:latest

# Centralized logging
docker run -d \
    --name app \
    --log-driver fluentd \
    --log-opt fluentd-address=localhost:24224 \
    --log-opt tag="docker.{{.Name}}" \
    myapp:latest
```

### 10.4 Backup Strategies
```bash
# Automated backup script
#!/bin/bash
backup_containers() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="/backup"
    
    # Backup running containers
    docker ps -q | while read container_id; do
        container_name=$(docker inspect -f '{{.Name}}' $container_id | sed 's/\///')
        docker commit $container_id "${container_name}_backup_${DATE}"
        docker save "${container_name}_backup_${DATE}" | gzip > "${BACKUP_DIR}/${container_name}_${DATE}.tar.gz"
    done
    
    # Backup volumes
    docker volume ls -q | while read volume_name; do
        docker run --rm \
            -v $volume_name:/source:ro \
            -v "${BACKUP_DIR}:/backup" \
            alpine tar czf "/backup/${volume_name}_${DATE}.tar.gz" -C /source .
    done
}
```

### Key Production Considerations:

1. **Monitoring & Alerting**
   - Set up comprehensive monitoring
   - Configure alerting thresholds
   - Implement log aggregation
   - Monitor resource usage

2. **Security**
   - Regular security scans
   - Update base images
   - Implement least privilege principle
   - Network segmentation

3. **Performance**
   - Resource optimization
   - Cache utilization
   - Network optimization
   - Storage performance

4. **Scalability**
   - Horizontal scaling
   - Load balancing
   - Service discovery
   - High availability

5. **Maintenance**
   - Backup strategies
   - Update procedures
   - Rollback plans
   - Disaster recovery

This part of the handbook focuses on production-ready Docker deployments, including advanced orchestration, security, monitoring, and optimization techniques. These practices are essential for running Docker in production environments.