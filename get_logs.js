const { execSync } = require('child_process');
const fs = require('fs');
try {
  const output = execSync('docker logs openclaw_agent', { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
  fs.writeFileSync('output.txt', output || 'EMPTY');
} catch (e) {
  fs.writeFileSync('output.txt', e.stderr || e.stdout || e.message);
}
