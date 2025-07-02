# 🐳 Docker DNS with `dnsmasq` and `docker-gen`

[![Docker Build](https://img.shields.io/docker/image-size/library/alpine/latest?label=dnsmasq&logo=docker)](https://hub.docker.com/_/alpine)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Made with Docker](https://img.shields.io/badge/made%20with-Docker-blue.svg)](https://www.docker.com/)
[![Status: Stable](https://img.shields.io/badge/status-stable-brightgreen)](#)

> Lightweight, ephemeral DNS server for local development — maps Docker containers to `*.test` automatically.

---

## 📚 Table of Contents

- [✨ Features](#-features)
- [⚙️ Prerequisites](#️-prerequisites)
- [🚀 Quick Start](#-quick-start)
- [🔍 How It Works](#-how-it-works)
- [🔧 Customization](#-customization)
- [🧩 Project Structure](#-project-structure)
- [🧪 Testing](#-testing)
- [📜 License](#-license)

---

## ✨ Features

- ✅ Automatic DNS resolution for `*.test` and more
- 🔁 Real-time updates via Docker events
- 🧼 No files on host — config stored in `tmpfs`
- 🧰 Minimal setup with Docker Compose
- 🧠 Extendable with custom domains

---

## ⚙️ Prerequisites

- Docker (20.10+)
- Docker Compose (v2+)
- Port `53` free on the host

---

## 🚀 Quick Start

1. **Clone the repository**:

   ```bash
   git clone https://github.com/hypermodular/dnsmasq.git
   cd dnsmasq
````

2. **Start the DNS server**:

   ```bash
   docker compose up -d
   ```

3. **Configure your system DNS**:

   * **Linux** (`/etc/resolv.conf` or `NetworkManager`):

     ```bash
     nameserver 127.0.0.1
     ```

   * **macOS** (create `/etc/resolver/test`):

     ```bash
     nameserver 127.0.0.1
     ```

4. **Run a test container**:

   ```bash
   docker run --name web -d nginx
   ping web.test
   ```

---

## 🔍 How It Works

* 🧠 `docker-gen` watches Docker for container events.
* 🛠️ It renders `dnsmasq.conf` based on container IPs and names.
* 🗂️ The config is loaded into a running `dnsmasq` instance.
* 📡 All `*.test` domains resolve to Docker containers via `127.0.0.1`.

---

## 🔧 Customization

To change domain suffixes (e.g. `*.dev`, `*.example.com`), edit:

```tmpl
# templates/dnsmasq.tmpl

address=/{{ container.Name }}.test/{{ container.IP }}
```

You can also add:

```tmpl
address=/{{ container.Name }}.dev/{{ container.IP }}
address=/{{ container.Name }}.example.com/{{ container.IP }}
```

---

## 🧩 Project Structure

```txt
dnsmasq/
├── templates/
│   └── dnsmasq.tmpl        # docker-gen template
├── entrypoint.sh           # startup logic
├── docker-compose.yml      # service definitions
└── README.md               # you are here
```

---

## 🧪 Testing

Check that domains resolve properly:

```bash
dig web.test @127.0.0.1
```

Expected output:

```
;; ANSWER SECTION:
web.test. 0 IN A 172.x.x.x
```

Or ping:

```bash
ping web.test
```

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

💡 **Need HTTPS + DNS + container routing?**
Ask about adding `nginx-proxy` and Let's Encrypt support!


