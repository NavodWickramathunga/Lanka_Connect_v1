# System Architecture Diagram

## Overview

Lanka Connect is a Flutter client application that uses Firebase services directly.  
For Spark/free demo mode, business side-effects are executed in-app through Firestore transactions/writes.

## Diagram (Spark-Compatible Runtime)

```mermaid
flowchart TB
    U[Users<br/>Seeker / Provider / Admin] --> A[Flutter App<br/>Android / iOS / Web]

    A --> AUTH[Firebase Auth]
    A --> FS[Cloud Firestore]
    A --> ST[Firebase Storage]

    subgraph AppDomain[Flutter App Domain Layers]
      UI[Screens + Widgets]
      UTIL[Services / Utils<br/>DemoDataService<br/>ReviewService<br/>ServiceModerationService]
      UI --> UTIL
    end

    A --> AppDomain
    UTIL --> FS
    UI --> FS
    UI --> ST
    UI --> AUTH

    subgraph DataCollections[Firestore Collections]
      USERS[users]
      SERVICES[services]
      BOOKINGS[bookings]
      REVIEWS[reviews]
      MESSAGES[messages]
      NOTIFS[notifications]
      PAYMENTS[payments]
    end

    FS --> DataCollections
```

## Key Runtime Responsibilities

- Authentication and role identity: Firebase Auth + `users/{uid}.role`.
- Data persistence and querying: Firestore collections.
- Profile images: Firebase Storage.
- Side effects (Spark mode, in-app):
  - Service post defaults to `pending`.
  - Admin approval writes moderation notification.
  - Review submission updates provider aggregate rating fields.
  - Admin demo data seeding performed in app code.
