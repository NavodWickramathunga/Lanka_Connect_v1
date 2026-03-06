// get_fresh_token.cjs - Uses firebase-tools internal auth to get a fresh token
const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');

const npmRoot = execSync('npm root -g', { stdio: ['pipe', 'pipe', 'pipe'] }).toString().trim();
const firebaseToolsPath = path.join(npmRoot, 'firebase-tools');

try {
  // Try using firebase-tools' requireAuth / api modules
  const { getTokens } = require(path.join(firebaseToolsPath, 'lib', 'auth'));
  const tokens = getTokens();
  console.log('getTokens result:', JSON.stringify(tokens).slice(0, 100));
} catch(e) {
  console.log('getTokens not available:', e.message.slice(0, 80));
}

// Alternative: look at what modules are available in firebase-tools lib
const libDir = path.join(firebaseToolsPath, 'lib');
const topLevelFiles = fs.readdirSync(libDir).filter(f => f.endsWith('.js') && !f.startsWith('test'));
console.log('\nTop-level firebase-tools lib files:');
topLevelFiles.slice(0, 20).forEach(f => console.log(' ', f));
