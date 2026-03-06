// refresh_token.cjs
// Refreshes the Firebase CLI access token using firebase-tools internals
const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');

const npmRoot = execSync('npm root -g').toString().trim();

// Try to find the client id / secret in firebase-tools
const authJsPath = path.join(npmRoot, 'firebase-tools', 'lib', 'auth.js');
const authContent = fs.readFileSync(authJsPath, 'utf8');

// Extract all potential secrets
const clientIdMatches = [...authContent.matchAll(/['"](563584335869-[^'"]+)['"]/g)];
const clientSecretMatches = [...authContent.matchAll(/['"](GOCSPX-[^'"]+)['"]/g)];
const allSecrets = [...authContent.matchAll(/client_secret[^:]*:[^'"]*['"]([A-Za-z0-9_\-]+)['"]/g)];

console.log('Client IDs found:', clientIdMatches.length);
clientIdMatches.forEach(m => console.log(' ID:', m[1]));

console.log('GOCSPX secrets found:', clientSecretMatches.length);
clientSecretMatches.forEach(m => console.log(' Secret:', m[1]));

console.log('All secrets:', allSecrets.length);
allSecrets.forEach(m => console.log(' Secret:', m[1]));
