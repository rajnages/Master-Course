#!/bin/bash

# Basic Build and Run
docker build -t my-image .                    # Build image from Dockerfile in current directory
docker run -p 80:80 my-image                  # Run container with port mapping

# Advanced Build Commands
docker build -t rajnages/my-image -f docker.dev . --no-cache    # Build with specific Dockerfile
docker build -t rajnages/my-image:v1 \
    --progress=plain \
    --build-arg T_VERSION='1.5.0' \
    --build-arg P_VERSION='1.4.0' \
    -f docker.dev . --no-cache                # Build with build args and specific tag

# Container Management
docker run --rm --name app2 \
    -p 8080:80 \
    -e AWS_ACCESS_KEY_ID=hidden \
    -e AWS_SECRET_KEY_ID=hidden              # Run with env variables and auto-remove

# Inspection Commands
docker images                                # List all images
docker ps                                    # List running containers
docker ps -a                                 # List all containers
docker exec -it app2 bash env               # View container environment variables

# Additional Useful Commands
docker logs container_name                   # View container logs
docker stop container_name                   # Stop a running container
docker rm container_name                     # Remove a container
docker rmi image_name                        # Remove an image
docker volume ls                            # List volumes
docker network ls                           # List networks

# Container Interaction
docker exec -it container_name bash         # Interactive shell into container
docker cp container_name:/src/path ./dest   # Copy files from container to host

# Docker Compose Commands
docker-compose up -d                        # Start services in detached mode
docker-compose down                         # Stop and remove containers
docker-compose logs -f                      # Follow logs of all services

# Clean Up Commands
docker system prune -a                      # Remove all unused containers, networks, images
docker volume prune                         # Remove all unused volumes

# Advanced Troubleshooting Commands
docker stats $(docker ps --format={{.Names}})   # Monitor resource usage of all running containers

# Quick Container Restart with Logs
docker restart container_name && docker logs -f container_name    # Restart and follow logs

# Cleanup and System Info
docker system df -v                         # Show detailed space usage
docker system info                         # Display system-wide information
docker system events --since 1h            # Show all events from last hour

# Advanced Inspection
docker inspect -f '{{.State.Health.Status}}' container_name     # Check container health status
docker inspect -f '{{.NetworkSettings.IPAddress}}' container_name    # Get container IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' container_name    # Get IP across networks

# Multi-Container Operations
docker stop $(docker ps -q)                # Stop all running containers
docker rm $(docker ps -aq)                 # Remove all containers
docker rmi $(docker images -q -f dangling=true)    # Remove all dangling images

# Network Troubleshooting
docker network inspect bridge              # Inspect default bridge network
docker run --rm --net container:app2 nicolaka/netshoot ss -tunlp    # Network debugging

# Log Analysis
docker logs --tail 1000 -f container_name | grep "error"    # Follow last 1000 lines with error filter
docker logs --since 5m container_name      # Show logs from last 5 minutes

# Performance Analysis
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"    # Resource usage snapshot
docker events --filter 'type=container' --filter 'event=die'    # Monitor container crashes

# Advanced Volume Management
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock alpine sh -c \
    "apk add --no-cache curl; curl --unix-socket /var/run/docker.sock http://localhost/containers/json"    # Inspect Docker API

# Container Debugging
docker run --name debug-container --rm -it \
    --network container:target-container \
    --pid container:target-container \
    alpine sh                             # Debug network/processes of another container

# Health Check Commands
for c in $(docker ps -q); do 
    echo "Container: $(docker inspect -f {{.Name}} $c)"; 
    echo "Status: $(docker inspect -f {{.State.Status}} $c)"; 
    echo "Health: $(docker inspect -f {{.State.Health.Status}} $c)"; 
done                                      # Check health of all containers

# Resource Limits Inspection
docker inspect -f '{{.HostConfig.Resources}}' container_name    # View resource constraints

# Security Inspection
docker inspect -f '{{.HostConfig.SecurityOpt}}' container_name  # View security options
docker top container_name                  # Show running processes in container

# Advanced Image Management
docker image history --no-trunc image_name   # View complete image build history
docker save image_name | gzip > image.tar.gz  # Export image with layers as archive
docker load < image.tar.gz                    # Load image from archive
docker image prune --filter "until=24h"       # Remove images older than 24h

# Advanced Container Diagnostics
docker run --rm --privileged -v /:/host alpine chroot /host ps aux    # View host processes from container
docker run -it --pid=container:target_container ubuntu nsenter -t 1 -m -u -n -i sh    # Enter container namespace

# Resource Monitoring with Prometheus Format
docker stats --no-stream --format "container_cpu_usage{container=\"{{ .Container }}\",name=\"{{ .Name }}\"} {{ .CPUPerc }}"

# Advanced Network Debugging
docker run --rm --net=container:target_container nicolaka/netshoot \
    tcpdump -i any -w capture.pcap           # Capture network traffic
docker run --rm --net=host nicolaka/netshoot \
    iperf3 -c target_ip                      # Network performance testing

# Container Security Analysis
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy image image_name           # Scan image for vulnerabilities

# Advanced Log Analysis
docker logs container_name 2>&1 | awk '
    BEGIN {count=0} 
    /error/ {count++} 
    END {print "Total errors:", count}'      # Count error occurrences

# Multi-Stage Cleanup
cleanup_docker() {
    docker stop $(docker ps -q) 2>/dev/null
    docker rm $(docker ps -aq) 2>/dev/null
    docker rmi $(docker images -q -f dangling=true) 2>/dev/null
    docker volume prune -f
    docker network prune -f
    docker system prune -af
}

# Advanced Container Metrics
docker run -d --name cadvisor \
    --volume=/:/rootfs:ro \
    --volume=/var/run:/var/run:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --publish=8080:8080 \
    google/cadvisor                          # Container performance monitoring

# Docker API Direct Interaction
curl --unix-socket /var/run/docker.sock \
    http://localhost/v1.41/containers/json    # Raw Docker API access

# Advanced Volume Backup
docker run --rm \
    --volumes-from source_container \
    -v $(pwd):/backup \
    alpine tar cvf /backup/backup.tar /data   # Backup volume data

# Container Process Debugging
docker run --rm -it \
    --pid=container:target_container \
    --net=container:target_container \
    --cap-add SYS_PTRACE \
    ubuntu strace -p 1                       # Trace container processes

# Advanced Health Monitoring
monitor_containers() {
    while true; do
        echo "=== Container Health Report $(date) ==="
        for container in $(docker ps --format "{{.Names}}"); do
            echo "Container: $container"
            docker stats --no-stream $container
            docker inspect --format "{{.State.Health.Status}}" $container
            echo "---"
        done
        sleep 60
    done
}

# Docker Registry Management
docker run -d \
    -p 5000:5000 \
    --restart=always \
    --name registry \
    -v /mnt/registry:/var/lib/registry \
    -v /mnt/certs:/certs \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
    registry:2                               # Setup private registry with TLS

# Advanced Container Debugging
debug_container() {
    container=$1
    docker run --rm -it \
        --pid container:$container \
        --net container:$container \
        --cap-add SYS_PTRACE \
        --security-opt seccomp=unconfined \
        ubuntu bash -c "
            apt-get update && 
            apt-get install -y gdb strace ltrace && 
            bash"                            # Advanced debugging tools
}

# Performance Profiling
docker run --rm \
    --privileged \
    --pid=host \
    -v /sys/kernel/debug:/sys/kernel/debug:rw \
    quay.io/iovisor/bpftrace \
    -e 'tracepoint:syscalls:sys_enter_* { @[probe] = count(); }'  # System call profiling
