/**
 * seed_full_production_firestore.mjs
 *
 * Builds the production Firestore (new-lanka-connect-app) to mirror the
 * staging (lankaconnect-app) structure with realistic demo data.
 *
 * Collections seeded (idempotent – safe to re-run):
 *   users                 – admin + demo_provider + demo_seeker
 *   services              – 6 approved + 1 pending
 *   requests              – 4 demo requests (pending/accepted/rejected/completed)
 *   bookings              – 4 bookings in different statuses
 *   messages              – realistic chat between seeker and provider
 *   notifications         – 5 notifications (request, booking, review, system)
 *   payments              – 2 payments (success / pending)
 *   reviews               – 3 reviews
 *   banners               – 3 active banners (unchanged)
 *
 * Usage:
 *   node scripts/seed_full_production_firestore.mjs
 */

import { readFileSync, writeFileSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';
import { createRequire } from 'module';
import { execSync } from 'child_process';

// ─── Config ───────────────────────────────────────────────────────────────────
const PROD   = 'new-lanka-connect-app';
const BASE   = 'https://firestore.googleapis.com/v1';

const ADMIN_UID    = 'DaEEU3TLwwOMdkAanWINCYmxiJn1';
const PROVIDER_UID = 'demo_provider';
const SEEKER_UID   = 'demo_seeker';

// ─── Token (auto-refresh via firebase-tools credentials) ──────────────────────
const cfgPath = join(homedir(), '.config', 'configstore', 'firebase-tools.json');

async function getFreshToken() {
  const cfg = JSON.parse(readFileSync(cfgPath, 'utf8'));
  try {
    const require = createRequire(import.meta.url);
    const npmRoot = execSync('npm root -g', { stdio: ['pipe','pipe','pipe'] }).toString().trim();
    const api = require(join(npmRoot, 'firebase-tools', 'lib', 'api'));
    const rt = cfg.tokens?.refresh_token;
    if (rt) {
      const r = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: rt, client_id: api.clientId(), client_secret: api.clientSecret() }),
      });
      const d = await r.json();
      if (d.access_token) {
        cfg.tokens.access_token = d.access_token;
        writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
        console.log('   ✓ OAuth token refreshed\n');
        return d.access_token;
      }
    }
  } catch { /* fall through */ }
  const stored = cfg.tokens?.access_token;
  if (!stored) { console.error('❌  Run: firebase login'); process.exit(1); }
  return stored;
}

const TOKEN = await getFreshToken();

// ─── REST helpers ─────────────────────────────────────────────────────────────
const hdrs = () => ({ Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' });

async function patch(collection, docId, fields) {
  const url = `${BASE}/projects/${PROD}/databases/(default)/documents/${collection}/${docId}`;
  const r = await fetch(url, { method: 'PATCH', headers: hdrs(), body: JSON.stringify({ fields }) });
  if (!r.ok) throw new Error(`PATCH ${collection}/${docId} → ${r.status} ${await r.text()}`);
}

// Create doc with auto-generated ID (POST to collection)
async function add(collection, fields) {
  const url = `${BASE}/projects/${PROD}/databases/(default)/documents/${collection}`;
  const r = await fetch(url, { method: 'POST', headers: hdrs(), body: JSON.stringify({ fields }) });
  if (!r.ok) throw new Error(`POST ${collection} → ${r.status} ${await r.text()}`);
  const d = await r.json();
  return d.name.split('/').pop(); // return generated ID
}

// ─── Firestore value builders ─────────────────────────────────────────────────
const s   = v  => ({ stringValue: String(v) });
const n   = v  => ({ doubleValue: Number(v) });
const i   = v  => ({ integerValue: String(Math.round(v)) });
const b   = v  => ({ booleanValue: Boolean(v) });
const arr = vs => ({ arrayValue: { values: vs } });
const map = o  => ({ mapValue: { fields: o } });
const now = () => ({ timestampValue: new Date().toISOString() });
const ts  = d  => ({ timestampValue: new Date(d).toISOString() });

// ─────────────────────────────────────────────────────────────────────────────
// 1. USERS
// ─────────────────────────────────────────────────────────────────────────────
async function seedUsers() {
  console.log('\n[1/9] Users…');

  await patch('users', ADMIN_UID, {
    role:      s('admin'),
    name:      s('Navod Wickramathunga'),
    email:     s('navod.wickramathunga@gmail.com'),
    isAdmin:   b(true),
    contact:   s('+94770000001'),
    district:  s('Colombo'),
    city:      s('Colombo'),
    createdAt: ts('2024-01-01'),
    updatedAt: now(),
  });
  console.log('   ✓ admin (Navod Wickramathunga)');

  await patch('users', PROVIDER_UID, {
    role:        s('provider'),
    name:        s('Kasun Perera'),
    email:       s('kasun.perera@lankaconnect.app'),
    contact:     s('+94771234567'),
    district:    s('Colombo'),
    city:        s('Maharagama'),
    bio:         s('Professional service provider with 5+ years experience in home services across Colombo.'),
    skills:      arr([s('Home Cleaning'), s('Plumbing'), s('AC Service'), s('Electrical')]),
    rating:      n(4.8),
    reviewCount: i(12),
    imageUrl:    s(''),
    createdAt:   ts('2024-01-15'),
    updatedAt:   now(),
  });
  console.log('   ✓ demo_provider (Kasun Perera)');

  await patch('users', SEEKER_UID, {
    role:      s('seeker'),
    name:      s('Amali Fernando'),
    email:     s('amali.fernando@lankaconnect.app'),
    contact:   s('+94779876543'),
    district:  s('Colombo'),
    city:      s('Nugegoda'),
    imageUrl:  s(''),
    createdAt: ts('2024-02-01'),
    updatedAt: now(),
  });
  console.log('   ✓ demo_seeker (Amali Fernando)');
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SERVICES
// ─────────────────────────────────────────────────────────────────────────────
async function seedServices() {
  console.log('\n[2/9] Services…');

  const services = [
    {
      id: 'demo_service_cleaning',
      title: 'Home Deep Cleaning', category: 'Cleaning',
      description: 'Full apartment / house deep clean including all rooms, kitchen, bathrooms, and balconies.',
      price: 3500, district: 'Colombo', city: 'Nugegoda', location: 'Nugegoda, Colombo',
      lat: 6.8649, lng: 79.8997, status: 'approved', date: '2024-02-01',
    },
    {
      id: 'demo_service_plumbing',
      title: 'Quick Plumbing Fix', category: 'Plumbing',
      description: 'Leak repairs, pipe fitting, tap replacement, and basic plumbing maintenance.',
      price: 2500, district: 'Gampaha', city: 'Kadawatha', location: 'Kadawatha, Gampaha',
      lat: 7.0014, lng: 79.9636, status: 'approved', date: '2024-02-05',
    },
    {
      id: 'demo_service_ac_repair',
      title: 'AC Repair & Servicing', category: 'Home Service',
      description: 'AC gas refill, full service and cleaning for all brands. Same-day service available.',
      price: 2500, district: 'Colombo', city: 'Colombo 07', location: 'Colombo 07, Colombo',
      lat: 6.9147, lng: 79.8605, status: 'approved', date: '2024-02-12',
    },
    {
      id: 'demo_service_carpentry',
      title: 'Carpenter & Woodwork', category: 'Carpentry',
      description: 'Custom furniture assembly, door/window fitting, and general woodwork repairs.',
      price: 1800, district: 'Colombo', city: 'Colombo 05', location: 'Colombo 05, Colombo',
      lat: 6.8935, lng: 79.8553, status: 'approved', date: '2024-02-15',
    },
    {
      id: 'demo_service_electrical',
      title: 'Home Electrical Work', category: 'Electrical',
      description: 'Wiring, socket installation, fan fitting, fuse repairs, and full electrical safety checks.',
      price: 3000, district: 'Kandy', city: 'Kandy', location: 'Kandy',
      lat: 7.2906, lng: 80.6337, status: 'approved', date: '2024-02-18',
    },
    {
      id: 'demo_service_painting',
      title: 'Interior Painting', category: 'Painting',
      description: 'Professional interior wall painting. All materials included. Per-room pricing available.',
      price: 5000, district: 'Galle', city: 'Galle', location: 'Galle',
      lat: 6.0535, lng: 80.2210, status: 'approved', date: '2024-02-20',
    },
    {
      id: 'demo_service_tutoring',
      title: 'Math Tutoring (O/L)', category: 'Tutoring',
      description: 'One-to-one O/L mathematics support sessions. Past papers & exam preparation included.',
      price: 2000, district: 'Colombo', city: 'Dehiwala', location: 'Dehiwala, Colombo',
      lat: 6.8516, lng: 79.8750, status: 'pending', date: '2024-02-22',
    },
  ];

  for (const svc of services) {
    await patch('services', svc.id, {
      providerId:  s(PROVIDER_UID),
      title:       s(svc.title),
      category:    s(svc.category),
      description: s(svc.description),
      price:       n(svc.price),
      district:    s(svc.district),
      city:        s(svc.city),
      location:    s(svc.location),
      lat:         n(svc.lat),
      lng:         n(svc.lng),
      status:      s(svc.status),
      createdAt:   ts(svc.date),
      updatedAt:   now(),
    });
    console.log(`   ✓ ${svc.id} – ${svc.title} [${svc.status}]`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. REQUESTS
// ─────────────────────────────────────────────────────────────────────────────
async function seedRequests() {
  console.log('\n[3/9] Requests…');

  const requests = [
    { id: 'demo_req_pending',   serviceId: 'demo_service_cleaning',  status: 'pending',   date: '2024-03-10' },
    { id: 'demo_req_accepted',  serviceId: 'demo_service_plumbing',  status: 'accepted',  date: '2024-03-05' },
    { id: 'demo_req_completed', serviceId: 'demo_service_ac_repair', status: 'completed', date: '2024-03-01' },
    { id: 'demo_req_rejected',  serviceId: 'demo_service_painting',  status: 'rejected',  date: '2024-02-28' },
  ];

  for (const req of requests) {
    await patch('requests', req.id, {
      serviceId:  s(req.serviceId),
      seekerId:   s(SEEKER_UID),
      providerId: s(PROVIDER_UID),
      status:     s(req.status),
      createdAt:  ts(req.date),
      updatedAt:  now(),
    });
    console.log(`   ✓ ${req.id} [${req.status}]`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. BOOKINGS
// ─────────────────────────────────────────────────────────────────────────────
async function seedBookings() {
  console.log('\n[4/9] Bookings…');

  const bookings = [
    { id: 'demo_booking_pending',    serviceId: 'demo_service_cleaning',   amount: 3500, status: 'pending',    date: '2024-03-10' },
    { id: 'demo_booking_accepted',   serviceId: 'demo_service_plumbing',   amount: 2500, status: 'accepted',   date: '2024-03-05' },
    { id: 'demo_booking_completed',  serviceId: 'demo_service_ac_repair',  amount: 2500, status: 'completed',  date: '2024-03-01' },
    { id: 'demo_booking_cancelled',  serviceId: 'demo_service_painting',   amount: 5000, status: 'cancelled',  date: '2024-02-28' },
  ];

  for (const bk of bookings) {
    await patch('bookings', bk.id, {
      serviceId:  s(bk.serviceId),
      seekerId:   s(SEEKER_UID),
      providerId: s(PROVIDER_UID),
      amount:     n(bk.amount),
      status:     s(bk.status),
      notes:      s('Demo booking – ' + bk.status),
      createdAt:  ts(bk.date),
      updatedAt:  now(),
    });
    console.log(`   ✓ ${bk.id} [${bk.status}]`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. MESSAGES  (stored in a chat sub-collection pattern via chatId)
// ─────────────────────────────────────────────────────────────────────────────
async function seedMessages() {
  console.log('\n[5/9] Messages…');

  const chatId = 'demo_chat_seeker_provider';
  const msgs = [
    { id: 'demo_msg_001', senderId: SEEKER_UID,   text: 'Hi, is the cleaning service available this Saturday?', date: '2024-03-11T09:00:00Z' },
    { id: 'demo_msg_002', senderId: PROVIDER_UID, text: 'Yes, I am available from 9 AM. Shall I confirm?',       date: '2024-03-11T09:05:00Z' },
    { id: 'demo_msg_003', senderId: SEEKER_UID,   text: 'Perfect! Please confirm for 9:30 AM.',                  date: '2024-03-11T09:08:00Z' },
    { id: 'demo_msg_004', senderId: PROVIDER_UID, text: 'Confirmed! See you Saturday at 9:30 AM.',               date: '2024-03-11T09:10:00Z' },
  ];

  for (const msg of msgs) {
    await patch('messages', msg.id, {
      chatId:    s(chatId),
      senderId:  s(msg.senderId),
      text:      s(msg.text),
      createdAt: ts(msg.date),
    });
    console.log(`   ✓ ${msg.id}: "${msg.text.substring(0, 40)}…"`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. NOTIFICATIONS
// ─────────────────────────────────────────────────────────────────────────────
async function seedNotifications() {
  console.log('\n[6/9] Notifications…');

  const notifs = [
    {
      id: 'demo_notif_request_created',
      title: 'New Service Request',
      body: 'A new request for "Home Deep Cleaning" is waiting for your action.',
      type: 'request',
      recipientId: PROVIDER_UID,
      senderId: SEEKER_UID,
      isRead: false,
      data: { serviceId: 'demo_service_cleaning', requestId: 'demo_req_pending', seekerId: SEEKER_UID, status: 'pending' },
      date: '2024-03-10T08:00:00Z',
    },
    {
      id: 'demo_notif_booking_accepted',
      title: 'Booking Accepted',
      body: 'Your booking for "Quick Plumbing Fix" has been accepted by the provider.',
      type: 'booking',
      recipientId: SEEKER_UID,
      senderId: PROVIDER_UID,
      isRead: true,
      data: { serviceId: 'demo_service_plumbing', bookingId: 'demo_booking_accepted', providerId: PROVIDER_UID, status: 'accepted' },
      date: '2024-03-05T10:00:00Z',
    },
    {
      id: 'demo_notif_booking_completed',
      title: 'Service Completed',
      body: 'Your AC Repair & Servicing has been marked as completed. Please leave a review!',
      type: 'booking',
      recipientId: SEEKER_UID,
      senderId: PROVIDER_UID,
      isRead: true,
      data: { serviceId: 'demo_service_ac_repair', bookingId: 'demo_booking_completed', providerId: PROVIDER_UID, status: 'completed' },
      date: '2024-03-01T16:00:00Z',
    },
    {
      id: 'demo_notif_review_received',
      title: 'New Review',
      body: 'Amali Fernando left you a 5-star review for "AC Repair & Servicing".',
      type: 'review',
      recipientId: PROVIDER_UID,
      senderId: SEEKER_UID,
      isRead: false,
      data: { serviceId: 'demo_service_ac_repair', reviewId: 'demo_review_ac', seekerId: SEEKER_UID, rating: 5 },
      date: '2024-03-02T09:00:00Z',
    },
    {
      id: 'demo_notif_system_welcome',
      title: 'Welcome to Lanka Connect!',
      body: 'Your account is ready. Browse services or list your own to get started.',
      type: 'system',
      recipientId: SEEKER_UID,
      senderId: 'system',
      isRead: true,
      data: {},
      date: '2024-02-01T00:00:00Z',
    },
  ];

  for (const notif of notifs) {
    await patch('notifications', notif.id, {
      title:       s(notif.title),
      body:        s(notif.body),
      type:        s(notif.type),
      recipientId: s(notif.recipientId),
      senderId:    s(notif.senderId),
      isRead:      b(notif.isRead),
      data:        map(Object.fromEntries(Object.entries(notif.data).map(([k,v]) => [k, s(String(v))]))),
      createdAt:   ts(notif.date),
    });
    console.log(`   ✓ ${notif.id} [${notif.type}] → ${notif.recipientId.substring(0,12)}…`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. PAYMENTS
// ─────────────────────────────────────────────────────────────────────────────
async function seedPayments() {
  console.log('\n[7/9] Payments…');

  const payments = [
    {
      id: 'demo_payment_success',
      bookingId: 'demo_booking_completed',
      serviceId: 'demo_service_ac_repair',
      amount: 2500, status: 'success', date: '2024-03-01',
    },
    {
      id: 'demo_payment_pending',
      bookingId: 'demo_booking_accepted',
      serviceId: 'demo_service_plumbing',
      amount: 2500, status: 'pending', date: '2024-03-05',
    },
  ];

  for (const pay of payments) {
    await patch('payments', pay.id, {
      bookingId:  s(pay.bookingId),
      serviceId:  s(pay.serviceId),
      seekerId:   s(SEEKER_UID),
      payerId:    s(SEEKER_UID),
      providerId: s(PROVIDER_UID),
      amount:     n(pay.amount),
      currency:   s('LKR'),
      gateway:    s('demo'),
      status:     s(pay.status),
      createdAt:  ts(pay.date),
    });
    console.log(`   ✓ ${pay.id} – LKR ${pay.amount} [${pay.status}]`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. REVIEWS
// ─────────────────────────────────────────────────────────────────────────────
async function seedReviews() {
  console.log('\n[8/9] Reviews…');

  const reviews = [
    {
      id: 'demo_review_ac',
      bookingId: 'demo_booking_completed',
      serviceId: 'demo_service_ac_repair',
      rating: 5,
      comment: 'Excellent service! Very professional and completed the job quickly. AC is working perfectly now.',
      date: '2024-03-02',
    },
    {
      id: 'demo_review_plumbing',
      bookingId: 'demo_booking_accepted',
      serviceId: 'demo_service_plumbing',
      rating: 4,
      comment: 'Good work, fixed the tap. Came on time and was very polite. Recommended.',
      date: '2024-03-06',
    },
    {
      id: 'demo_review_cleaning',
      bookingId: 'demo_booking_pending',
      serviceId: 'demo_service_cleaning',
      rating: 5,
      comment: 'Thorough cleaning – every corner was spotless. Will definitely book again.',
      date: '2024-03-12',
    },
  ];

  for (const rev of reviews) {
    await patch('reviews', rev.id, {
      bookingId:  s(rev.bookingId),
      serviceId:  s(rev.serviceId),
      providerId: s(PROVIDER_UID),
      reviewerId: s(SEEKER_UID),
      rating:     i(rev.rating),
      comment:    s(rev.comment),
      createdAt:  ts(rev.date),
    });
    console.log(`   ✓ ${rev.id} – ${rev.rating}★  "${rev.comment.substring(0, 45)}…"`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. BANNERS  (keep existing, refresh if needed)
// ─────────────────────────────────────────────────────────────────────────────
async function seedBanners() {
  console.log('\n[9/9] Banners…');

  const banners = [
    { id: 'banner_001', title: 'Spring Cleaning Sale',   subtitle: 'Get 20% off all deep cleaning services this week!',     ctaText: 'Book Now',    colorHex: '2563EB', order: 1 },
    { id: 'banner_002', title: 'Emergency Plumbing?',    subtitle: 'Expert plumbers available 24/7 across Sri Lanka.',        ctaText: 'Find Help',   colorHex: '0891B2', order: 2 },
    { id: 'banner_003', title: 'Join as a Provider',     subtitle: 'Grow your business and reach thousands of customers.',   ctaText: 'Register',    colorHex: '0D9488', order: 3 },
  ];

  for (const bar of banners) {
    await patch('banners', bar.id, {
      title:     s(bar.title),
      subtitle:  s(bar.subtitle),
      ctaText:   s(bar.ctaText),
      colorHex:  s(bar.colorHex),
      imageUrl:  s(''),
      active:    b(true),
      order:     i(bar.order),
      createdAt: ts('2024-01-01'),
    });
    console.log(`   ✓ ${bar.id}: "${bar.title}"`);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('╔═══════════════════════════════════════════════════════╗');
  console.log('║  Lanka Connect – Full Production Firestore Setup      ║');
  console.log('║  Project : new-lanka-connect-app                      ║');
  console.log('╚═══════════════════════════════════════════════════════╝');

  await seedUsers();
  await seedServices();
  await seedRequests();
  await seedBookings();
  await seedMessages();
  await seedNotifications();
  await seedPayments();
  await seedReviews();
  await seedBanners();

  console.log('');
  console.log('╔═══════════════════════════════════════════════════════╗');
  console.log('║  ✅  All 9 collections seeded successfully!           ║');
  console.log('╚═══════════════════════════════════════════════════════╝');
  console.log('');
  console.log('  Collection     Docs');
  console.log('  ─────────────────────────────────────────────');
  console.log('  users          3  (admin + provider + seeker)');
  console.log('  services       7  (6 approved, 1 pending)');
  console.log('  requests       4  (pending / accepted / completed / rejected)');
  console.log('  bookings       4  (pending / accepted / completed / cancelled)');
  console.log('  messages       4  (provider ↔ seeker chat)');
  console.log('  notifications  5  (request / booking / review / system)');
  console.log('  payments       2  (success / pending)');
  console.log('  reviews        3  (4–5 star reviews)');
  console.log('  banners        3  (active promotional banners)');
  console.log('');
  console.log('  Admin login: navod.wickramathunga@gmail.com');
  console.log('  Demo users:  kasun.perera@lankaconnect.app  (provider)');
  console.log('               amali.fernando@lankaconnect.app (seeker)');
  console.log('');
  console.log('  Tip: Use Admin Panel → Dashboard → Banners tab to add real banner images.');
}

main().catch(err => { console.error('\n❌', err.message); process.exit(1); });
