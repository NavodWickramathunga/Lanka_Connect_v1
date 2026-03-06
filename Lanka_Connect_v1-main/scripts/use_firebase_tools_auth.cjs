// use_firebase_tools_auth.cjs
// Uses firebase-tools' own auth module to get a valid access token (handles refresh internally)
const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');

const npmRoot = execSync('npm root -g', { stdio: ['pipe','pipe','pipe'] }).toString().trim();
const ftPath = path.join(npmRoot, 'firebase-tools');

// firebase-tools uses google-auth-library underneath
// The refreshAccessToken is done via the api module
const api = require(path.join(ftPath, 'lib', 'api'));
const auth = require(path.join(ftPath, 'lib', 'auth'));

// Print what's exported
console.log('api exports:', Object.keys(api));
console.log('auth exports:', Object.keys(auth));
