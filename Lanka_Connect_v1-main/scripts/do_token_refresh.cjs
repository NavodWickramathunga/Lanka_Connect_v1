// do_token_refresh.cjs - Refreshes Firebase CLI token and updates the config file
const path = require('path');
const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');

const npmRoot = execSync('npm root -g', { stdio: ['pipe','pipe','pipe'] }).toString().trim();
const ftPath = path.join(npmRoot, 'firebase-tools');

const api  = require(path.join(ftPath, 'lib', 'api'));
const auth = require(path.join(ftPath, 'lib', 'auth'));

console.log('clientId:', api.clientId?.slice(0, 30) + '…');
console.log('clientSecret:', api.clientSecret?.slice(0, 10) + '…');

const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));

const refreshToken = cfg.tokens?.refresh_token;
if (!refreshToken) { console.error('No refresh_token in config'); process.exit(1); }

console.log('\nRefreshing token…');

fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: api.clientId,
    client_secret: api.clientSecret,
  }),
})
  .then(r => r.json())
  .then(d => {
    if (d.access_token) {
      cfg.tokens.access_token = d.access_token;
      fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
      console.log('✅ Token refreshed! Length:', d.access_token.length);
      console.log('   Expires in:', d.expires_in, 'seconds');
    } else {
      console.error('❌ Token refresh failed:', JSON.stringify(d));
    }
  })
  .catch(e => console.error('Error:', e));
