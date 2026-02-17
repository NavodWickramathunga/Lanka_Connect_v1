# Firestore Schema and Collections

## Collections

### `users/{userId}`

Purpose: profile, role, and provider aggregates.

Common fields:

- `role`: `seeker | provider | admin` (plus normalized legacy provider labels in rules)
- `name`: string
- `contact`: string
- `district`: string
- `city`: string
- `skills`: string[]
- `bio`: string
- `imageUrl`: string
- `averageRating`: number (provider aggregate)
- `reviewCount`: number (provider aggregate)
- `createdAt`: timestamp
- `updatedAt`: timestamp

### `services/{serviceId}`

Purpose: service marketplace posts.

Fields:

- `providerId`: string (`users/{uid}`)
- `title`: string
- `category`: string
- `price`: number
- `district`: string
- `city`: string
- `location`: string
- `lat`: number (optional)
- `lng`: number (optional)
- `description`: string
- `status`: `pending | approved | rejected`
- `createdAt`: timestamp
- `updatedAt`: timestamp

### `bookings/{bookingId}`

Purpose: service booking lifecycle.

Fields:

- `serviceId`: string
- `providerId`: string
- `seekerId`: string
- `amount`: number
- `status`: `pending | accepted | rejected | completed`
- `createdAt`: timestamp
- `updatedAt`: timestamp

### `reviews/{reviewId}`

Purpose: post-completion rating and comment.

Fields:

- `bookingId`: string
- `serviceId`: string
- `providerId`: string
- `reviewerId`: string
- `rating`: int (1..5)
- `comment`: string
- `createdAt`: timestamp

### `messages/{messageId}`

Purpose: booking-linked chat.

Fields:

- `chatId`: string (booking id)
- `senderId`: string
- `text`: string
- `createdAt`: timestamp

### `notifications/{notificationId}`

Purpose: user alerts and moderation/payment/request signals.

Fields:

- `recipientId`: string
- `senderId`: string
- `title`: string
- `body`: string
- `type`: string
- `data`: map (optional structured payload)
- `isRead`: bool
- `readAt`: timestamp (optional)
- `createdAt`: timestamp

### `payments/{paymentId}`

Purpose: demo payment records.

Fields:

- `seekerId`: string
- `providerId`: string
- `serviceId`: string
- `bookingId`: string
- `gateway`: `demo`
- `status`: `success | failed`
- `amount`: number
- `createdAt`: timestamp

### `requests/{requestId}`

Purpose: request/offer style flow (if used).

Fields:

- `serviceId`: string
- `providerId`: string
- `seekerId`: string
- `status`: string
- `createdAt`: timestamp
- `updatedAt`: timestamp

## Notes for Assessment

- Read patterns are role-filtered in UI and rules.
- Service discovery for seekers is status-filtered to `approved`.
- Provider aggregate fields are materialized on `users` for quick reads.
