# Acer home-server staging deployment

This configuration is **staging only**. Keep the current Render deployment and Google Play testing release unchanged until end-to-end verification.

## Prerequisites
- Ubuntu host with Docker Engine and Compose.
- Clone this branch to a separate folder, e.g. /opt/tempo100.
- Create a local `.env` from `.env.example`. **Never commit .env or share SVV_API_KEY.**
- For real lookups, set `DATA_MODE=live` and `SVV_API_KEY` to the existing key from the secure Render environment; for safe initial checks use `DATA_MODE=demo`.

## Start and verify
```sh
docker compose -f compose.acer.yaml config --quiet
docker compose -f compose.acer.yaml up -d --build
docker compose -f compose.acer.yaml ps
curl -fsS http://127.0.0.1:3000/api/config
docker stats --no-stream tempo100
```
The API is deliberately bound to **127.0.0.1:3000** on the Acer host. This prevents accidental exposure on the home network/internet. Access from Windows using an SSH tunnel: `ssh -N -L 3000:127.0.0.1:3000 arildb88@10.0.0.61`, then open `http://127.0.0.1:3000`.

## Before replacing Render
1. Verify actual live lookup with a known trailer, including API key and errors, without logging plates.
2. Select a stable public HTTPS hostname and secure reverse proxy/tunnel with access control and rate limiting. Do not open router ports directly without a security review.
3. The Google Play release is compiled with `API_BASE_URL`; existing installations **will not automatically switch from Render**. Build and publish an updated release pointing at the new HTTPS endpoint, or introduce a carefully managed stable endpoint.
4. Check availability, power/network outages, privacy policy URL, Google Play listing, monitoring, backups and SVV API limits.
5. Keep Render until existing testers have migrated and a rollback is ready.

## Resource notes
- Docker limits Tempo100 to 256 MiB RAM and 0.5 CPU; measure actual usage alongside ProfitTrailer.
- The server has no database. Its daily lookup counter and rate limits are process-local and reset on restart. A proxy-level persistent quota is advisable before public access.
- Docker restart policy restarts the container, not a disconnected home internet link or power outage.
