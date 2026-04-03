const { execSync } = require('child_process');
const fs = require('fs');
try {
  console.log("Stopping...");
  execSync('docker compose down', { stdio: 'inherit' });
  console.log("Starting...");
  execSync('docker compose up -d', { stdio: 'inherit' });
  fs.writeFileSync('restart.log', 'Success');
} catch (e) {
  fs.writeFileSync('restart.log', 'Error: ' + e.message);
}
