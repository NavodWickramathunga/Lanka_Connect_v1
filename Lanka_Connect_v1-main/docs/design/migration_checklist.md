# UI Migration Checklist

Incremental revamp checklist. Keep logic and backend behavior unchanged.

## Phase 0: Foundation
- [x] Add design token source (`lib/ui/theme/design_tokens.dart`)
- [x] Wire mobile + web token wrappers
- [x] Update base theme usage
- [x] Add reusable state panels for mobile/web
- [x] Freeze handoff docs in `docs/design/*`

## Phase 1: Auth + entry
- [ ] `lib/screens/auth/auth_screen.dart`
- [ ] `lib/screens/permissions/required_permissions_screen.dart`
- [ ] Verify role portal gating still enforced

## Phase 2: Services
- [ ] `lib/screens/services/service_list_screen.dart`
- [ ] `lib/screens/services/service_detail_screen.dart`
- [ ] `lib/screens/services/service_form_screen.dart`
- [ ] `lib/screens/services/service_map_screen.dart`
- [ ] `lib/widgets/service_map_preview.dart`

## Phase 3: Requests + bookings
- [ ] `lib/screens/requests/request_list_screen.dart`
- [ ] `lib/screens/requests/seeker_request_list_screen.dart`
- [ ] `lib/screens/bookings/booking_list_screen.dart`

## Phase 4: Chat + notifications
- [ ] `lib/screens/chat/chat_list_screen.dart`
- [ ] `lib/screens/chat/chat_screen.dart`
- [ ] `lib/screens/notifications/notifications_screen.dart`

## Phase 5: Profile + reviews + payments
- [ ] `lib/screens/profile/profile_screen.dart`
- [ ] `lib/screens/reviews/review_form_screen.dart`
- [ ] `lib/screens/payments/payment_screen.dart`

## Phase 6: Admin web
- [ ] `lib/screens/admin/admin_services_screen.dart`
- [ ] `lib/screens/admin/admin_web_dashboard_screen.dart`

## Per-PR quality gates
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] before/after screenshots attached
- [ ] behavior lock checks passed:
  - [ ] role permissions
  - [ ] status transitions
  - [ ] notification side effects
  - [ ] chat-to-booking linkage
