/**
 * setup_production_firestore.mjs
 *
 * Seeds the production Firestore database (new-lanka-connect-app) with demo
 * collections that mirror the staging (lankaconnect-app) structure.
 *
 * Collections seeded:
 *   users        – admin doc + demo_provider
 *   services     – 5 approved demo services + 1 pending
 *   banners      – 3 active promotional banners
 *   bookings     – 2 demo bookings (accepted / completed)
 *   reviews      – 1 demo review
 *
 * Prerequisites:
 *   - Node 18 +  (native fetch)
 *   - Firebase CLI logged in (firebase login)
 *     Token is read from ~/.config/configstore/firebase-tools.json
 *
 * Usage:
 *   node scripts/setup_production_firestore.mjs
 */

import { readFileSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';

// ─── Config ──────────────────────────────────────────────────────────────────
const PROD_PROJECT   = 'new-lanka-connect-app';
const STAGING_PROJECT = 'lankaconnect-app';
const ADMIN_UID      = 'DaEEU3TLwwOMdkAanWINCYmxiJn1';
const ADMIN_EMAIL    = 'navod.wickramathunga@gmail.com';
const ADMIN_NAME     = 'Navod Wickramathunga';

const BASE_URL = 'https://firestore.googleapis.com/v1';

// ─── Load cached Firebase OAuth token ────────────────────────────────────────
const configPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
const firebaseCfg = JSON.parse(readFileSync(configPath, 'utf8'));
const TOKEN = firebaseCfg.tokens?.access_token;
if (!TOKEN) {
  console.error('❌  No Firebase OAuth token found. Run: firebase login');
  process.exit(1);
}

// ─── REST helpers ─────────────────────────────────────────────────────────────
function authHeaders() {
  return { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };
}

async function fsGet(path) {
  const url = `${BASE_URL}/projects/${PROD_PROJECT}/databases/(default)/documents${path}`;
  const r = await fetch(url, { headers: authHeaders() });
  if (!r.ok) throw new Error(`GET ${path} → ${r.status}: ${await r.text()}`);
  return r.json();
}

async function fsPatch(collection, docId, fields) {
  const path = `/projects/${PROD_PROJECT}/databases/(default)/documents/${collection}/${docId}`;
  const r = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers: authHeaders(),
    body: JSON.stringify({ fields }),
  });
  if (!r.ok) throw new Error(`PATCH ${collection}/${docId} → ${r.status}: ${await r.text()}`);
  return r.json();
}

async function stagingGet(collection, pageSize = 100) {
  const url = `${BASE_URL}/projects/${STAGING_PROJECT}/databases/(default)/documents/${collection}?pageSize=${pageSize}`;
  const r = await fetch(url, { headers: authHeaders() });
  if (!r.ok) return [];
  const data = await r.json();
  return data.documents ?? [];
}

// ─── Firestore value builders ─────────────────────────────────────────────────
const str   = v  => ({ stringValue: String(v) });
const num   = v  => ({ doubleValue: Number(v) });
const int   = v  => ({ integerValue: String(Math.round(v)) });
const bool  = v  => ({ booleanValue: Boolean(v) });
const arr   = vs => ({ arrayValue: { values: vs } });
const now   = () => ({ timestampValue: new Date().toISOString() });
const ts    = d  => ({ timestampValue: new Date(d).toISOString() });

// ─── Seed steps ──────────────────────────────────────────────────────────────

async function seedAdminUser() {
  console.log('[1/6] Admin user document…');
  await fsPatch('users', ADMIN_UID, {
    role:      str('admin'),
    email:     str(ADMIN_EMAIL),
    name:      str(ADMIN_NAME),
    isAdmin:   bool(true),
    contact:   str('+94770000001'),
    district:  str('Colombo'),
    city:      str('Colombo'),
    createdAt: ts('2024-01-01'),
    updatedAt: now(),
  });
  console.log('   ✓ admin doc updated\n');
}

async function seedDemoProvider() {
  console.log('[2/6] Demo provider user…');
  await fsPatch('users', 'demo_provider', {
    role:        str('provider'),
    name:        str('Demo Provider'),
    email:       str('demo.provider@lankaconnect.app'),
    contact:     str('+94770000000'),
    district:    str('Colombo'),
    city:        str('Maharagama'),
    skills:      arr([str('Home Cleaning'), str('Plumbing'), str('AC Service')]),
    bio:         str('Demo profile for presentation and testing purposes.'),
    rating:      num(4.8),
    reviewCount: int(12),
    createdAt:   ts('2024-01-01'),
    updatedAt:   now(),
  });
  console.log('   ✓ demo_provider created\n');
}

async function seedServices() {
  console.log('[3/6] Services…');

  // Service definitions – all tied to demo_provider
  const services = [
    {
      id: 'demo_service_cleaning',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('Home Deep Cleaning'),
        category:    str('Cleaning'),
        description: str('Full apartment / house deep clean. Includes all rooms, kitchen, and bathrooms.'),
        price:       num(3500),
        location:    str('Nugegoda, Colombo'),
        district:    str('Colombo'),
        city:        str('Nugegoda'),
        status:      str('approved'),
        createdAt:   ts('2024-02-01'),
        updatedAt:   now(),
      },
    },
    {
      id: 'demo_service_plumbing',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('Quick Plumbing Fix'),
        category:    str('Plumbing'),
        description: str('Leak repairs, pipe fitting, tap replacement, and basic plumbing maintenance.'),
        price:       num(2500),
        location:    str('Kadawatha, Gampaha'),
        district:    str('Gampaha'),
        city:        str('Kadawatha'),
        status:      str('approved'),
        createdAt:   ts('2024-02-05'),
        updatedAt:   now(),
      },
    },
    {
      id: 'demo_service_tutoring',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('Math Tutoring (O/L)'),
        category:    str('Tutoring'),
        description: str('One-to-one O/L mathematics support sessions. Past papers & exam preparation included.'),
        price:       num(2000),
        location:    str('Dehiwala, Colombo'),
        district:    str('Colombo'),
        city:        str('Dehiwala'),
        status:      str('pending'),
        createdAt:   ts('2024-02-10'),
        updatedAt:   now(),
      },
    },
    {
      id: 'demo_service_ac_repair',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('AC Repair & Servicing'),
        category:    str('Home Service'),
        description: str('AC gas refill, full service and cleaning for all brands.'),
        price:       num(2500),
        location:    str('Colombo'),
        district:    str('Colombo'),
        city:        str('Colombo'),
        status:      str('approved'),
        createdAt:   ts('2024-02-12'),
        updatedAt:   now(),
      },
    },
    {
      id: 'demo_service_carpentry',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('Carpenter & Woodwork'),
        category:    str('Carpentry'),
        description: str('Custom furniture, door/window fitting, and general woodwork repairs.'),
        price:       num(1800),
        location:    str('Colombo 07, Colombo'),
        district:    str('Colombo'),
        city:        str('Colombo 07'),
        status:      str('approved'),
        createdAt:   ts('2024-02-15'),
        updatedAt:   now(),
      },
    },
    {
      id: 'demo_service_electrical',
      fields: {
        providerId:  str('demo_provider'),
        title:       str('Home Electrical Work'),
        category:    str('Electrical'),
        description: str('Wiring, socket installation, fan fitting, fuse repairs, and safety checks.'),
        price:       num(3000),
        location:    str('Kandy'),
        district:    str('Kandy'),
        city:        str('Kandy'),
        status:      str('approved'),
        createdAt:   ts('2024-02-18'),
        updatedAt:   now(),
      },
    },
  ];

  for (const svc of services) {
    await fsPatch('services', svc.id, svc.fields);
    console.log(`   ✓ ${svc.id}: ${svc.fields.title.stringValue}`);
  }
  console.log();
}

async function seedBanners() {
  console.log('[4/6] Banners…');
  // Staging has 0 banners – create fresh demo banners
  // colorHex is stored WITHOUT the leading '#' (matches BannerData.fromMap default '2563EB')
  const banners = [
    {
      id: 'banner_001',
      fields: {
        title:     str('Spring Cleaning Sale'),
        subtitle:  str('Get 20% off all deep cleaning services this week!'),
        ctaText:   str('Book Now'),
        colorHex:  str('2563EB'),
        imageUrl:  str(''),
        active:    bool(true),
        order:     int(1),
        createdAt: now(),
      },
    },
    {
      id: 'banner_002',
      fields: {
        title:     str('Emergency Plumbing?'),
        subtitle:  str('Expert plumbers available 24/7 across Sri Lanka.'),
        ctaText:   str('Find Help'),
        colorHex:  str('0891B2'),
        imageUrl:  str(''),
        active:    bool(true),
        order:     int(2),
        createdAt: now(),
      },
    },
    {
      id: 'banner_003',
      fields: {
        title:     str('Join as a Pro'),
        subtitle:  str('Expand your business and reach thousands of seekers.'),
        ctaText:   str('Register'),
        colorHex:  str('0D9488'),
        imageUrl:  str(''),
        active:    bool(true),
        order:     int(3),
        createdAt: now(),
      },
    },
  ];

  for (const b of banners) {
    await fsPatch('banners', b.id, b.fields);
    console.log(`   ✓ ${b.id}: "${b.fields.title.stringValue}"`);
  }
  console.log();
}

async function seedBookings() {
  console.log('[5/6] Demo bookings…');
  const uid6 = ADMIN_UID.substring(0, 6);

  await fsPatch('bookings', `demo_booking_accepted_${uid6}`, {
    serviceId:  str('demo_service_cleaning'),
    providerId: str('demo_provider'),
    seekerId:   str(ADMIN_UID),
    amount:     num(3500),
    status:     str('accepted'),
    notes:      str('Please clean the kitchen thoroughly.'),
    createdAt:  ts('2024-03-01'),
    updatedAt:  now(),
  });
  console.log(`   ✓ demo_booking_accepted_${uid6} (cleaning / accepted)`);

  await fsPatch('bookings', `demo_booking_completed_${uid6}`, {
    serviceId:  str('demo_service_plumbing'),
    providerId: str('demo_provider'),
    seekerId:   str(ADMIN_UID),
    amount:     num(2500),
    status:     str('completed'),
    notes:      str('Tap in bathroom keeps leaking.'),
    createdAt:  ts('2024-03-05'),
    updatedAt:  now(),
  });
  console.log(`   ✓ demo_booking_completed_${uid6} (plumbing / completed)\n`);
}

async function seedReviews() {
  console.log('[6/6] Demo review…');
  const uid6 = ADMIN_UID.substring(0, 6);

  await fsPatch('reviews', `demo_review_${uid6}`, {
    bookingId:   str(`demo_booking_completed_${uid6}`),
    serviceId:   str('demo_service_plumbing'),
    providerId:  str('demo_provider'),
    reviewerId:  str(ADMIN_UID),
    rating:      int(5),
    comment:     str('Very reliable and quick. Fixed the leak in under 30 minutes. Highly recommended.'),
    createdAt:   ts('2024-03-06'),
  });
  console.log(`   ✓ demo_review_${uid6} (plumbing, 5 ★)\n`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║   Lanka Connect – Production Firestore Setup     ║');
  console.log('║   Project: new-lanka-connect-app                 ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');

  await seedAdminUser();
  await seedDemoProvider();
  await seedServices();
  await seedBanners();
  await seedBookings();
  await seedReviews();

  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║   ✅  All collections seeded successfully!       ║');
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
  console.log('Collections written:');
  console.log('  users      → admin doc + demo_provider');
  console.log('  services   → 6 services (5 approved, 1 pending)');
  console.log('  banners    → 3 active promotional banners');
  console.log('  bookings   → 2 demo bookings (accepted / completed)');
  console.log('  reviews    → 1 demo review (5 stars)');
  console.log('');
  console.log(`Sign in at https://new-lanka-connect-app.web.app as:`);
  console.log(`  ${ADMIN_EMAIL}  (admin)`);
  console.log('');
  console.log('Tip: Use the Admin panel → Dashboard → Banners tab to add real banners with images.');
}

main().catch(err => {
  console.error('\n❌  Fatal error:', err.message);
  process.exit(1);
});
