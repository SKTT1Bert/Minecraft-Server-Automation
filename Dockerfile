# Minecraft Server Dockerfile
FROM openjdk:17-jdk-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create minecraft user and directory
RUN useradd -m -s /bin/bash minecraft
WORKDIR /opt/minecraft

# Download Minecraft server
RUN wget -O minecraft_server.jar https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar

# Create EULA file
RUN echo "eula=true" > eula.txt

# Copy server configuration
COPY server.properties .
COPY start-server.sh .
RUN chmod +x start-server.sh

# Create data directory for persistence
RUN mkdir -p /data && chown minecraft:minecraft /data

# Change ownership
RUN chown -R minecraft:minecraft /opt/minecraft

# Switch to minecraft user
USER minecraft

# Expose Minecraft port
EXPOSE 25565

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD netstat -an | grep -q ":25565 " || exit 1

# Start command
CMD ["./start-server.sh"] 