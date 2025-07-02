# Docker DNS with dnsmasq and docker-gen

A lightweight DNS server that automatically creates DNS entries for your Docker containers.

## Features

- Automatic DNS resolution for `*.test` domains
- No persistent files on the host (uses tmpfs)
- Automatic container discovery
- Simple setup with Docker Compose

## Prerequisites

- Docker
- Docker Compose
- Port 53 available on your host

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/hypermodular/dnsmasq.git
   cd docker-dns
   ```

2. Start the DNS server:
   ```bash
   docker compose up -d
   ```

3. Configure your system to use the local DNS server:
   - **Linux**: Edit `/etc/resolv.conf` and add:
     ```
     nameserver 127.0.0.1
     ```
   - **macOS**: Create `/etc/resolver/test` with:
     ```
     nameserver 127.0.0.1
     ```

4. Test with a container:
   ```bash
   docker run --name web -d nginx
   ping web.test
   ```

## How It Works

- `dnsmasq` serves as the DNS server
- `docker-gen` watches for container events and updates the DNS configuration
- Configuration is stored in memory (`/tmp`)
- All `*.test` domains are resolved to your local containers

## Customization

Edit `templates/dnsmasq.tmpl` to modify DNS behavior or add custom domains.

## License

