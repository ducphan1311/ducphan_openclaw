const { execSync } = require('child_process');
const fs = require('fs');
try {
  const output = execSync('docker exec openclaw_agent openclaw agents list', { encoding: 'utf-8' });
  fs.writeFileSync('output.txt', output || 'EMPTY');
} catch (e) {
  fs.writeFileSync('output.txt', e.stderr || e.stdout || e.message);
}
