from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.state import DashboardStore


REPO_ROOT = Path(__file__).resolve().parents[1]

app = FastAPI(
    title="Health Dashboard",
    description="Internal-only health and scoring dashboard for the Hill AFB capstone lab.",
    version="0.1.0",
)
app.mount("/static", StaticFiles(directory=str(REPO_ROOT / "static")), name="static")
templates = Jinja2Templates(directory=str(REPO_ROOT / "templates"))
store = DashboardStore()


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "page_title": "Health Dashboard",
            "api_state_url": "/api/state",
        },
    )


@app.get("/healthz")
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok"})


@app.get("/api/state")
async def state() -> JSONResponse:
    return JSONResponse(store.snapshot())


@app.post("/api/monitor/start")
async def start_monitor() -> JSONResponse:
    started = store.start_monitor("live")
    return JSONResponse({"started": started, "state": store.snapshot()})


@app.post("/api/monitor/demo")
async def start_demo() -> JSONResponse:
    started = store.start_monitor("demo")
    return JSONResponse({"started": started, "state": store.snapshot()})


@app.post("/api/monitor/stop")
async def stop_monitor() -> JSONResponse:
    stopped = store.stop_monitor()
    return JSONResponse({"stopped": stopped, "state": store.snapshot()})
