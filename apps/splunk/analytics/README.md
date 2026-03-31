# Analytics & Detection Rules (Splunk)

This directory contains resources for configuring Splunk data inputs and detection logic.

## 1. Data Collection (`inputs.conf`)
To ingest logs from custom sources (e.g., a specific app log), create an `inputs.conf` app on the Deployment Server or manually on the Forwarder.

**Example `inputs.conf`**:
```ini
[monitor:///var/log/auth.log]
disabled = 0
index = linux_logs
sourcetype = syslog
```

## 2. Detection Logic (`rules/`)
Place your SPL queries here. We recommend saving them as `.spl` files for version control.

### Cheat Sheet: Common Queries

**Detect Failed Logins (Linux):**
```splunk
index=linux_logs sourcetype=syslog "Failed password"
| stats count by user, src_ip
| where count > 5
```

**Detect USB Insertion (Kernel):**
```splunk
index=linux_logs sourcetype=syslog "New USB device found"
| table _time, host, message
```

**Detect High CPU Usage:**
```splunk
index=os_metrics sourcetype=cpu
| stats avg(usage) as avg_usage by host
| where avg_usage > 90
```
