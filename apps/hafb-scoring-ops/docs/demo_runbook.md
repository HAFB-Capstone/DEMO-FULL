# Demo Runbook

## Startup

```bash
cd /Users/taylorpreslar/capstone/hafb-scoring-ops
./scripts/setup_demo.sh
./scripts/run_demo.sh
```

Open `http://127.0.0.1:8000`.

## Recommended Demonstration Flow

1. Show the header and identify the dashboard as an internal evaluator view.
2. Point to the current score and the two tracked vulnerability families.
3. Click `Demo`.
4. Call out that the timer starts immediately and the dashboard begins returning per-endpoint results.
5. Walk through each family card:
   - endpoint count
   - returned status code
   - latency when present
   - family score
6. Click `Stop`.
7. Confirm that the timer stops and the last recorded score remains visible.

## Talking Points

- The score is derived from backend checks, not from client-side calculations.
- Each family score is based on how many configured endpoints return HTTP `200`.
- The overall dashboard score is the mean of the family scores.
- The same dashboard supports both deterministic demo checks and live internal checks.

## Transition To Live Monitoring

When target services are available on the lab network:

1. Launch the dashboard on `controlOps`.
2. Click `Start` instead of `Demo`.
3. Confirm that `controlOps` can reach the configured internal endpoints.
4. Use the same display to review live availability and score changes.
