# Firestore Rules Summary (Role Protection)

Source of truth: `firestore.rules`.

## Authentication Baseline

- Most access requires `request.auth != null`.
- User role is resolved from `users/{uid}.role`.

## Role Model

- `seeker`: default end-user searching and booking services.
- `provider`: can create services and handle booking state transitions.
- `admin`: moderation, broader read/write powers where explicitly allowed.

## Access Control Summary by Collection

### `users`

- Create:
  - self-create allowed for `seeker`/`provider`.
  - admin can create user docs (needed for in-app seed flow).
- Read:
  - self or admin.
- Update:
  - admin unrestricted.
  - self-update allowed with role immutability guard.
  - controlled non-self aggregate update allowed for provider rating fields only:
    - changed keys restricted to `averageRating`, `reviewCount`, `updatedAt`
    - `reviewCount` must increase by exactly 1
    - `averageRating` must stay in `[0, 5]`

### `services`

- Read:
  - approved services visible to signed-in users.
  - providers can read own services.
  - admin can read all.
- Create:
  - provider can create own service only with `status == pending`.
  - admin can create service docs for seeding/moderation scenarios.
- Update:
  - provider can edit own service while keeping status unchanged.
  - admin can change only `status` and `updatedAt`.

### `bookings`

- Read: participants (provider/seeker) or admin.
- Create:
  - seeker only, for existing service/provider pairing, initial `status == pending`.
- Update:
  - provider state machine enforced:
    - `pending -> accepted|rejected`
    - `accepted -> completed`
  - admin override allowed.

### `reviews`

- Create allowed only if:
  - reviewer is signed-in seeker.
  - referenced booking exists and belongs to reviewer/provider/service.
  - booking status is `completed`.
  - rating range is valid (`1..5`).
- Update/Delete: denied.

### `messages`

- Read/Create restricted to booking participants via `chatId`.
- Update/Delete: denied.

### `notifications`

- Read: recipient or admin.
- Create:
  - sender must equal authenticated user.
- Update:
  - only recipient can mark read.
  - changed keys limited to `isRead` and `readAt`.

### `payments`

- Create:
  - seeker-only for own accepted booking.
  - consistency checks for provider/service/booking.
  - demo gateway and status/value validation.
- Update/Delete: denied.

## Security Posture Notes

- Principle of least privilege is applied with per-collection constraints.
- Cross-document invariants are validated in rules using `get()`/`exists()`.
- Critical state transitions are locked to role-specific workflows.
