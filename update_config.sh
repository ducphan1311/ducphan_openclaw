#!/bin/bash
docker exec openclaw_agent openclaw config set agents.defaults.model "google/gemini-2.5-flash"
docker exec openclaw_agent openclaw config set agents.defaults.provider "google"
docker exec openclaw_agent sh -c 'cat ~/.openclaw/openclaw.json'
