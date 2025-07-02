.PHONY: up down restart logs status test clean setup-linux setup-macos kill-ports help env

# Default DNS port
DNS_PORT ?= 53

# Export all variables to sub-makes
export

# Create dnsmasq.env file if it doesn't exist
dnsmasq.env:
	@echo "# DNS Configuration" > dnsmasq.env
	@echo "DNS_PORT=${DNS_PORT}" >> dnsmasq.env
	@echo "# Note: This file is generated. Do not edit directly." >> dnsmasq.env
	@chmod 644 dnsmasq.env
	@echo "Created dnsmasq.env file with default values"

# Default target
all: help

# Show help
help:
	@echo "\n\033[1mDocker DNS Management\033[0m\n"
	@echo "\033[1mAvailable targets:\033[0m"
	@echo "  \033[1mup\033[0m         - Start the dnsmasq service (kills processes on required ports)"
	@echo "  \033[1mdown\033[0m       - Stop and remove the containers"
	@echo "  \033[1mrestart\033[0m    - Restart the service"
	@echo "  \033[1mlogs\033[0m       - Show service logs"
	@echo "  \033[1mstatus\033[0m     - Show container status"
	@echo "  \033[1mtest\033[0m       - Test DNS resolution"
	@echo "  \033[1mclean\033[0m      - Remove all generated files and stop containers"
	@echo "  \033[1mkill-ports\033[0m  - Kill processes on ports 53, 5353, 5354 (TCP/UDP)"
	@echo "  \033[1msetup-linux\033[0m - Configure Linux to use local DNS (requires root)"
	@echo "  \033[1msetup-macos\033[0m - Configure macOS to use local DNS"
	@echo ""

# Load environment variables from dnsmasq.env
include dnsmasq.env

export DNS_PORT ?= 5353

# Kill processes on required ports
kill-ports:
	@echo "\033[1mKilling processes on port ${DNS_PORT} (TCP/UDP)...\033[0m"
	@echo "Checking port ${DNS_PORT}..."
	@if command -v lsof >/dev/null 2>&1; then \
		sudo lsof -i :${DNS_PORT} -sTCP:LISTEN -t 2>/dev/null | xargs -r sudo kill -9 2>/dev/null || true; \
		sudo lsof -i udp:${DNS_PORT} -t 2>/dev/null | xargs -r sudo kill -9 2>/dev/null || true; \
	elif command -v fuser >/dev/null 2>&1; then \
		sudo fuser -k ${DNS_PORT}/tcp 2>/dev/null || true; \
		sudo fuser -k ${DNS_PORT}/udp 2>/dev/null || true; \
	else \
		echo "Could not find lsof or fuser. Please install one of them to kill processes."; \
		exit 1; \
	fi
	@echo "Port ${DNS_PORT} cleared successfully"

# Instructions to free port 53
free-port-53:
	@echo "\033[1m=== Port 53 Configuration Required ===\033[0m"
	@echo "To use port 53, you need to run the following command with sudo:"
	@echo "  sudo scripts/free-port-53.sh"
	@echo ""
	@echo "After running the above command, run 'make up' again."
	@echo ""
	@exit 1

# Start the service
up: dnsmasq.env kill-ports
	@echo "\033[1mStarting dnsmasq service on port ${DNS_PORT}...\033[0m"
	@docker compose --env-file dnsmasq.env up -d
	@echo "\n\033[1;32m✓ dnsmasq is running on port ${DNS_PORT}\033[0m"
	@echo "Test with: make test"

# Stop and remove containers
down:
	@echo "\033[1mStopping dnsmasq service...\033[0m"
	@docker compose down

# Restart the service
restart: down up

# Show service logs
logs:
	@docker compose logs -f

# Show container status
status:
	@docker compose ps

# Test DNS resolution
test:
	@echo "\n\033[1mTesting DNS resolution...\033[0m"
	@if ! docker ps | grep -q dev-dns; then \
		echo "Error: dnsmasq container is not running. Run 'make up' first."; \
		exit 1; \
	fi
	@echo "Querying local DNS for web.test on port ${DNS_PORT}..."
	@if ! command -v dig &> /dev/null; then \
		echo "dig command not found. Install dnsutils or bind-tools package."; \
		exit 1; \
	fi
	@dig +short web.test @127.0.0.1 -p ${DNS_PORT} || (echo "\n\033[31m✗ DNS query failed. Is the service running on port ${DNS_PORT}?\033[0m" && exit 1)

# Clean up
clean: down
	@echo "\033[1mCleaning up...\033[0m"
	@rm -f dnsmasq.conf
	@docker network prune -f >/dev/null 2>&1 || true
	@echo "Cleanup complete"

# Configure Linux to use local DNS (requires root)
setup-linux:
	@if [ ! -f /etc/NetworkManager/conf.d/docker-dns.conf ]; then \
		echo "\033[1mConfiguring NetworkManager to use local DNS...\033[0m"; \
		echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/docker-dns.conf > /dev/null; \
		echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null; \
		echo "Restarting NetworkManager..."; \
		sudo systemctl restart NetworkManager; \
		echo "\033[1;32m✓ NetworkManager configured for dnsmasq\033[0m"; \
	else \
		echo "NetworkManager is already configured for dnsmasq"; \
	fi

# Configure macOS to use local DNS
setup-macos:
	@if [ ! -d /etc/resolver ]; then \
		sudo mkdir -p /etc/resolver; \
	fi
	@if [ ! -f /etc/resolver/test ]; then \
		echo "\033[1mConfiguring macOS resolver for .test domain...\033[0m"; \
		echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null; \
		echo "\033[1;32m✓ macOS resolver configured for .test domain\033[0m"; \
		echo "You may need to restart your network services for changes to take effect"; \
	else \
		echo "macOS resolver is already configured for .test domain"; \
	fi

stop:
	sudo scripts/free-port-53.sh
	sudo scripts/free-port-80.sh
	sudo scripts/free-port-5353.sh
	sudo scripts/free-port-8000.sh
	sudo scripts/free-port-8080.sh