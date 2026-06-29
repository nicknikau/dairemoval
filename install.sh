#!/bin/bash

# Professional UI Styling Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        Welcome to the PodRip Installer        ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. System Requirements Check
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed on this system."
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# 2. License Onboarding & Validation Callout
echo -e "🎟️  Don't have a license key? Get one instantly at:"
echo -e "👉 ${GREEN}https://podrip.nikautech.nz${NC} (Redirects directly to our store)\n"

# </dev/tty forces the script to wait for physical keyboard input during curls
read -p "🔑 Enter your PodRip License Key: " LICENSE_KEY </dev/tty
if [ -z "$LICENSE_KEY" ]; then
    echo "❌ Error: License key cannot be empty."
    exit 1
fi

# 3. Collect Secure Media Directory
read -p "📁 Enter absolute path to your Audiobooks folder (e.g., /mnt/user/audiobooks): " USER_MEDIA_PATH </dev/tty
if [ ! -d "$USER_MEDIA_PATH" ]; then
    echo "⚠️ Target directory does not exist. Creating it now..."
    mkdir -p "$USER_MEDIA_PATH"
fi

# 4. Create Isolated Workspace Directory
TARGET_DIR="/opt/podrip"
echo -e "\n🚀 Setting up production workspace in ${TARGET_DIR}..."
sudo mkdir -p "$TARGET_DIR"
sudo chown -R $USER:$USER "$TARGET_DIR"
cd "$TARGET_DIR"

# 5. Generate the Docker Compose File pointing strictly to nikautech/podrip
cat << COMPOSE_EOF > docker-compose.yml
services:
  podrip-engine:
    image: nikautech/podrip:latest
    container_name: podrip-engine
    environment:
      - PYTHONUNBUFFERED=1
      - LICENSE_KEY=${LICENSE_KEY}
    volumes:
      - ${USER_MEDIA_PATH}:/media
    entrypoint: ["sh", "-c", "while true; do /usr/local/bin/media-validator; sleep 60; done"]
    restart: unless-stopped
COMPOSE_EOF

# 6. Bring the Stack Online
echo -e "${GREEN}📦 Pulling secure binary layers from nikautech/podrip registry...${NC}"
docker compose up -d --force-recreate

echo -e "\n${GREEN}✅ PodRip Installation Complete!${NC}"
echo "The engine is securely monitoring your library folder every 60 seconds."
echo "To view your live license verification stream, run: cd $TARGET_DIR && docker compose logs -f"
