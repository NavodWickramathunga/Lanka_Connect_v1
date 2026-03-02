import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();

setGlobalOptions({maxInstances: 10});

export const setServicePendingOnCreate = onDocumentCreated("services/{serviceId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    return;
  }

  const data = snapshot.data();
  if (data.status === "pending") {
    return;
  }

  await snapshot.ref.update({status: "pending"});
  logger.info("Forced new service status to pending", {
    serviceId: event.params.serviceId,
  });
});

export const notifyOnServiceApproval = onDocumentUpdated("services/{serviceId}", async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) {
    return;
  }

  if (before.status === "approved" || after.status !== "approved") {
    return;
  }

  const providerId = (after.providerId ?? "").toString();
  if (!providerId) {
    logger.warn("Skipping service approval notification: missing providerId", {
      serviceId: event.params.serviceId,
    });
    return;
  }

  await db.collection("notifications").add({
    recipientId: providerId,
    senderId: "system",
    title: "Service approved",
    body: "Your service has been approved by admin.",
    type: "service_moderation",
    data: {
      serviceId: event.params.serviceId,
      status: "approved",
    },
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  logger.info("Created approval notification", {
    serviceId: event.params.serviceId,
    providerId,
  });
});

export const updateProviderRatingOnReviewCreate = onDocumentCreated("reviews/{reviewId}", async (event) => {
  const data = event.data?.data();
  if (!data) {
    return;
  }

  const providerId = (data.providerId ?? "").toString();
  const rawRating = data.rating;
  const rating = typeof rawRating === "number" ? rawRating : Number(rawRating);

  if (!providerId || Number.isNaN(rating) || rating < 1 || rating > 5) {
    logger.warn("Skipping rating aggregate update due to invalid review payload", {
      reviewId: event.params.reviewId,
      providerId,
      rawRating,
    });
    return;
  }

  const providerRef = db.collection("users").doc(providerId);

  await db.runTransaction(async (tx) => {
    const providerSnap = await tx.get(providerRef);
    const providerData = providerSnap.data() ?? {};

    const currentAverage = Number(providerData.averageRating ?? 0);
    const currentCount = Number(providerData.reviewCount ?? 0);
    const safeAverage = Number.isFinite(currentAverage) ? currentAverage : 0;
    const safeCount = Number.isFinite(currentCount) && currentCount > 0 ? currentCount : 0;

    const newCount = safeCount + 1;
    const newAverage = ((safeAverage * safeCount) + rating) / newCount;

    tx.set(providerRef, {
      averageRating: Number(newAverage.toFixed(2)),
      reviewCount: newCount,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  logger.info("Updated provider rating aggregate", {
    reviewId: event.params.reviewId,
    providerId,
  });
});

export const seedDemoData = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in before seeding demo data.");
  }

  const callerRef = db.collection("users").doc(callerUid);
  const callerSnap = await callerRef.get();
  const callerRole = (callerSnap.data()?.role ?? "").toString().toLowerCase();
  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admin can seed demo data.");
  }

  const providerId = "demo_provider";
  const approvedServiceOneId = "demo_service_cleaning";
  const approvedServiceTwoId = "demo_service_plumbing";
  const pendingServiceId = "demo_service_tutoring";
  const acceptedBookingId = `demo_booking_accepted_${callerUid.substring(0, 6)}`;
  const completedBookingId = `demo_booking_completed_${callerUid.substring(0, 6)}`;
  const reviewId = `demo_review_${callerUid.substring(0, 6)}`;

  const batch = db.batch();

  const providerRef = db.collection("users").doc(providerId);
  batch.set(providerRef, {
    role: "provider",
    name: "Demo Provider",
    contact: "+94770000000",
    district: "Colombo",
    city: "Maharagama",
    skills: ["Home Cleaning", "Plumbing"],
    bio: "Demo profile for presentation and testing.",
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const serviceOneRef = db.collection("services").doc(approvedServiceOneId);
  batch.set(serviceOneRef, {
    providerId,
    title: "Home Deep Cleaning",
    category: "Cleaning",
    price: 3500,
    district: "Colombo",
    city: "Nugegoda",
    location: "Nugegoda, Colombo",
    description: "Apartment and house deep cleaning service.",
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const serviceTwoRef = db.collection("services").doc(approvedServiceTwoId);
  batch.set(serviceTwoRef, {
    providerId,
    title: "Quick Plumbing Fix",
    category: "Plumbing",
    price: 2500,
    district: "Gampaha",
    city: "Kadawatha",
    location: "Kadawatha, Gampaha",
    description: "Leak repairs and basic plumbing maintenance.",
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const pendingServiceRef = db.collection("services").doc(pendingServiceId);
  batch.set(pendingServiceRef, {
    providerId,
    title: "Math Tutoring (O/L)",
    category: "Tutoring",
    price: 2000,
    district: "Colombo",
    city: "Dehiwala",
    location: "Dehiwala, Colombo",
    description: "One-to-one O/L maths support sessions.",
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const acceptedBookingRef = db.collection("bookings").doc(acceptedBookingId);
  batch.set(acceptedBookingRef, {
    serviceId: approvedServiceOneId,
    providerId,
    seekerId: callerUid,
    amount: 3500,
    status: "accepted",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const completedBookingRef = db.collection("bookings").doc(completedBookingId);
  batch.set(completedBookingRef, {
    serviceId: approvedServiceTwoId,
    providerId,
    seekerId: callerUid,
    amount: 2500,
    status: "completed",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const reviewRef = db.collection("reviews").doc(reviewId);
  batch.set(reviewRef, {
    bookingId: completedBookingId,
    serviceId: approvedServiceTwoId,
    providerId,
    reviewerId: callerUid,
    rating: 5,
    comment: "Reliable and quick service. Great for demo data.",
    createdAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  const notificationRef = db.collection("notifications").doc();
  batch.set(notificationRef, {
    recipientId: callerUid,
    senderId: "system",
    title: "Demo data ready",
    body: "Seed completed successfully. Refresh tabs to view sample data.",
    type: "system",
    data: {
      services: [approvedServiceOneId, approvedServiceTwoId, pendingServiceId],
      bookings: [acceptedBookingId, completedBookingId],
    },
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  await serviceOneRef.update({
    status: "approved",
    updatedAt: FieldValue.serverTimestamp(),
  });
  await serviceTwoRef.update({
    status: "approved",
    updatedAt: FieldValue.serverTimestamp(),
  });

  logger.info("Seeded demo data for admin user", {callerUid});

  return {
    ok: true,
    providerId,
    services: [approvedServiceOneId, approvedServiceTwoId, pendingServiceId],
    bookings: [acceptedBookingId, completedBookingId],
    reviewId,
  };
});

// ── FCM Push Notification on Firestore notification creation ──
export const sendPushOnNotificationCreate = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const recipientId = (data.recipientId ?? "").toString();
    const title = (data.title ?? "Lanka Connect").toString();
    const body = (data.body ?? "").toString();

    if (!recipientId || recipientId === "__admins__") {
      // Admin channel notifications: send to all admins
      if (recipientId === "__admins__") {
        const adminsSnap = await db.collection("users")
          .where("role", "==", "admin")
          .get();

        const tokens: string[] = [];
        for (const adminDoc of adminsSnap.docs) {
          const adminData = adminDoc.data();
          if (adminData.fcmToken) {
            tokens.push(adminData.fcmToken);
          }
        }

        if (tokens.length > 0) {
          try {
            const response = await getMessaging().sendEachForMulticast({
              tokens,
              notification: {title, body},
              data: {
                notificationId: event.params.notificationId,
                type: (data.type ?? "general").toString(),
              },
            });
            logger.info("Sent admin push notifications", {
              successCount: response.successCount,
              failureCount: response.failureCount,
            });
          } catch (err) {
            logger.error("Failed to send admin push", {error: err});
          }
        }
      }
      return;
    }

    // Single recipient: look up their FCM token
    const recipientDoc = await db.collection("users").doc(recipientId).get();
    const recipientData = recipientDoc.data();
    const fcmToken = recipientData?.fcmToken;

    if (!fcmToken) {
      logger.info("No FCM token for recipient, skipping push", {recipientId});
      return;
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {title, body},
        data: {
          notificationId: event.params.notificationId,
          type: (data.type ?? "general").toString(),
        },
        android: {
          priority: "high",
          notification: {
            channelId: "lanka_connect_notifications",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      });

      logger.info("Push notification sent", {
        notificationId: event.params.notificationId,
        recipientId,
      });
    } catch (err) {
      logger.error("Failed to send push notification", {
        notificationId: event.params.notificationId,
        recipientId,
        error: err,
      });
    }
  }
);
