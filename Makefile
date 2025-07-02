.PHONY: up down restart logs status test clean setup-linux setup-macos

# Default target
all: help

# Show help
help:
	@echo "Available targets:"
	@echo "  up         - Start the dnsmasq service"
	@echo "  down       - Stop and remove the containers"
	@echo "  restart    - Restart the service"
	@echo "  logs       - Show service logs"
	@echo "  status     - Show container status"
	@echo "  test       - Test DNS resolution"
	@echo "  clean      - Remove all generated files"
	@echo "  setup-linux - Configure Linux to use local DNS (requires root)"
	@echo "  setup-macos - Configure macOS to use local DNS"

# Start the service
up:
	docker compose up -d

# Stop and remove containers
down:
	docker compose down

# Restart the service
restart: down up

# Show service logs
logs:
	docker compose logs -f

# Show container status
status:
	docker compose ps

# Test DNS resolution
test:
	@echo "Testing DNS resolution..."
	@if ! docker ps | grep -q dev-dns; then \
		echo "Error: dnsmasq container is not running. Run 'make up' first."; \
		exit 1; \
	fi
	@echo "Querying local DNS for web.test..."
	@dig +short web.test @127.0.0.1 || (echo "\nError: DNS query failed. Is the service running?" && exit 1)

# Remove all generated files
clean:
	sudo rm -f /tmp/dnsmasq.conf

# Configure Linux to use local DNS (requires root)
setup-linux:
	@if [ ! -f /etc/NetworkManager/conf.d/docker-dns.conf ]; then \
		echo "Configuring NetworkManager to use local DNS..."; \
		echo -e "[main]\ndns=dnsmasq" | sudo tee /etc/NetworkManager/conf.d/docker-dns.conf > /dev/null; \
		echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf > /dev/null; \
		echo "Restarting NetworkManager..."; \
		sudo systemctl restart NetworkManager; \
	else \
		echo "NetworkManager is already configured for dnsmasq"; \
	fi

# Configure macOS to use local DNS
setup-macos:
	@if [ ! -d /etc/resolver ]; then \
		sudo mkdir -p /etc/resolver; \
	fi
	@if [ ! -f /etc/resolver/test ]; then \
		echo "Configuring macOS resolver for .test domain..."; \
		echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null; \
	else \
		echo "macOS resolver is already configured for .test domain"; \
	fi
	@echo "You may need to restart your network services for changes to take effect"
