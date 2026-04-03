# Availability Result Schema

The dashboard stores monitoring results as family-level availability records. These records are returned through `/api/state` and rendered directly by the frontend.

## Family-Level Fields

- `name`
  - operator-facing label for the vulnerability family
- `status`
  - one of `healthy`, `degraded`, `unhealthy`, or `pending`
- `healthy_checks`
  - number of checks that returned HTTP `200`
- `total_checks`
  - total number of configured checks in the family
- `score`
  - family score from `0` to `100`
- `detail`
  - concise summary of the family result
- `checks`
  - array of individual endpoint results

## Check-Level Fields

- `id`
  - stable identifier used by the backend
- `name`
  - operator-facing label
- `url`
  - internal endpoint checked from `controlOps`
- `http_status`
  - returned HTTP status code when present
- `latency_ms`
  - measured latency in milliseconds when available
- `status`
  - one of `healthy`, `unhealthy`, or `pending`
- `detail`
  - short textual explanation such as `HTTP 200 OK`, `HTTP 503`, or connection error text

## Why This Shape Works

This schema keeps the monitor output compact and easy to explain:

- operators can see the exact endpoint associated with each family
- evaluators can understand how the score was produced
- new families and checks can be added without changing the rendering model

The schema is also stable across live mode and demo mode, which allows the same dashboard and API response shape to be used in both cases.
