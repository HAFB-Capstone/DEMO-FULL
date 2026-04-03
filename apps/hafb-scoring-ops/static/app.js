const stateUrl = window.dashboardConfig.stateUrl;
const pollIntervalMs = 1000;

const el = {
  missionStatusLabel: document.getElementById("mission-status-label"),
  missionStatusChip: document.getElementById("mission-status-chip"),
  missionStatusDetail: document.getElementById("mission-status-detail"),
  monitorModeLabel: document.getElementById("monitor-mode-label"),
  monitorTimer: document.getElementById("monitor-timer"),
  monitorLastChecked: document.getElementById("monitor-last-checked"),
  monitorLabel: document.getElementById("monitor-label"),
  generatedAt: document.getElementById("generated-at"),
  scoreRing: document.getElementById("score-ring"),
  scoreRingValue: document.getElementById("score-ring-value"),
  vulnerabilityScope: document.getElementById("vulnerability-scope"),
  startButton: document.getElementById("start-btn"),
  demoButton: document.getElementById("demo-btn"),
  stopButton: document.getElementById("stop-btn"),
};

async function fetchState() {
  const response = await fetch(stateUrl);
  if (!response.ok) {
    throw new Error("Failed to load dashboard state");
  }
  return response.json();
}

async function postAction(url) {
  const response = await fetch(url, { method: "POST" });
  if (!response.ok) {
    throw new Error(`Action failed: ${url}`);
  }
  return response.json();
}

function render(state) {
  const monitor = state.monitor ?? {};

  el.missionStatusLabel.textContent = state.mission_status.label;
  el.missionStatusDetail.textContent = state.mission_status.detail;
  el.monitorModeLabel.textContent = capitalize(monitor.mode ?? "idle");
  el.monitorTimer.textContent = formatDuration(monitor.elapsed_seconds ?? 0);
  el.monitorLastChecked.textContent = formatTimestamp(monitor.last_checked_at);
  el.monitorLabel.textContent = monitor.label ?? "Awaiting start";
  el.generatedAt.textContent = `Updated ${formatTimestamp(state.generated_at)}`;
  el.scoreRingValue.textContent = state.score;
  el.scoreRing.style.background = scoreGradient(state.score);

  setStatusChip(el.missionStatusChip, state.mission_status.label);
  renderScope(state.vulnerability_scope ?? []);

  const isRunning = monitor.status === "running";
  el.startButton.disabled = isRunning;
  el.demoButton.disabled = isRunning;
  el.stopButton.disabled = !isRunning;
}

function renderScope(items) {
  el.vulnerabilityScope.innerHTML = items.map((item) => `
    <div class="source-item">
      <div class="feed-top">
        <strong>${escapeHtml(item.name)}</strong>
        <span class="${badgeClass(item.status)}">${escapeHtml(item.score)} / 100</span>
      </div>
      <p>${escapeHtml(item.detail)}</p>
      <div class="check-summary">${escapeHtml(item.healthy_checks)} / ${escapeHtml(item.total_checks)} endpoints healthy</div>
      <div class="check-list">
        ${item.checks.map((check) => `
          <div class="check-row">
            <div>
              <strong>${escapeHtml(check.name)}</strong>
              <div class="check-url">${escapeHtml(check.url)}</div>
            </div>
            <div class="check-status-block">
              <span class="${badgeClass(check.status)}">${escapeHtml(checkLabel(check))}</span>
              <div class="check-url">${escapeHtml(check.detail)}${check.latency_ms ? ` | ${check.latency_ms} ms` : ""}</div>
            </div>
          </div>
        `).join("")}
      </div>
    </div>
  `).join("");
}

function checkLabel(check) {
  if (check.status === "healthy") {
    return "200";
  }
  if (check.status === "pending") {
    return "PENDING";
  }
  return check.http_status ? String(check.http_status) : "DOWN";
}

function scoreGradient(score) {
  const degrees = Math.max(0, Math.min(360, Math.round((score / 100) * 360)));
  let color = "var(--accent)";
  if (score < 75) {
    color = "var(--danger)";
  } else if (score < 90) {
    color = "var(--warn)";
  }
  return `conic-gradient(${color} ${degrees}deg, rgba(255, 255, 255, 0.08) ${degrees}deg)`;
}

function setStatusChip(target, label) {
  target.textContent = label;
  target.className = "status-chip";
  if (label === "Degraded") {
    target.classList.add("status-warning");
  } else if (label === "Incident Response") {
    target.classList.add("status-danger");
  } else if (label === "Idle" || label === "Stopped") {
    target.classList.add("status-neutral");
  }
}

function badgeClass(status) {
  if (status === "unhealthy" || status === "down") {
    return "status-chip status-danger";
  }
  if (status === "degraded") {
    return "status-chip status-warning";
  }
  if (status === "pending" || status === "idle" || status === "stopped" || status === "demo") {
    return "status-chip status-neutral";
  }
  return "status-chip";
}

function formatTimestamp(value) {
  if (!value) {
    return "n/a";
  }
  const date = new Date(value);
  return `${date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" })}`;
}

function formatDuration(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function capitalize(value) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

async function refresh() {
  try {
    render(await fetchState());
  } catch (error) {
    console.error(error);
  }
}

el.startButton.addEventListener("click", async () => {
  await postAction("/api/monitor/start");
  await refresh();
});

el.demoButton.addEventListener("click", async () => {
  await postAction("/api/monitor/demo");
  await refresh();
});

el.stopButton.addEventListener("click", async () => {
  await postAction("/api/monitor/stop");
  await refresh();
});

refresh();
setInterval(refresh, pollIntervalMs);
