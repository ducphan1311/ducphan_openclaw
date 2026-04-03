FROM node:22-slim

# Install system dependencies for browser automation and tools
RUN apt-get update && apt-get install -y \
    wget gnupg ca-certificates \
    chromium \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Add a non-root user for security
RUN groupadd -r openclawgroup && useradd -r -g openclawgroup -m openclawuser

WORKDIR /app

# Install openclaw
RUN npm install -g openclaw@latest playwright pnpm

# Create required directories for memory, skills, and config
RUN mkdir -p /app/workspace /app/skills /app/config && \
    chown -R openclawuser:openclawgroup /app

# Switch to the non-root user
USER openclawuser

# Set environment variables
ENV OPENCLAW_WORKSPACE=/app/workspace
ENV OPENCLAW_SKILLS_DIR=/app/skills
ENV OPENCLAW_CONFIG_DIR=/app/config
ENV OPENCLAW_HOST=127.0.0.1
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Copy and setup entrypoint script
COPY --chown=openclawuser:openclawgroup entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Expose web dashboard port (will bind to localhost in compose)
EXPOSE 3000
EXPOSE 18789
EXPOSE 18791

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["openclaw", "gateway", "--allow-unconfigured", "--port", "3000"]
