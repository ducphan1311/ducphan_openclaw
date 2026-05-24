#!/usr/bin/env python3
"""Create an Obsidian report stub for Hanoi date spot research."""
from pathlib import Path
from datetime import datetime
import sys
vault = Path.home() / 'Documents/Obsidian/OpenClawBrain'
template = Path(__file__).resolve().parents[1] / 'templates/date_spot_report.md'
outdir = vault / '70-Logs/Research'
outdir.mkdir(parents=True, exist_ok=True)
date = datetime.now().strftime('%Y-%m-%d')
request = ' '.join(sys.argv[1:]).strip() or 'Hanoi date spot research'
content = template.read_text()
content = content.replace('{{date}}', date).replace('{{request}}', request).replace('{{assumptions}}', 'Hanoi, couple date, practical and trending options.')
out = outdir / f'hanoi-date-spots-{date}.md'
if out.exists():
    out = outdir / f'hanoi-date-spots-{datetime.now().strftime("%Y-%m-%d-%H%M%S")}.md'
out.write_text(content)
print(out)
