/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyBudgetThreshold = functions.firestore
  .document("users/{userId}/budgets/{month}")
  .onWrite(async (change, context) => {
    const after = change.after.data();
    const before = change.before.exists ? change.before.data() : null;
    if (!after) return null;

    const amount = after.amount;
    const spent = after.spent;
    if (!amount || !spent) return null;

    // Only notify if spent increased
    if (before && spent <= before.spent) return null;

    const userId = context.params.userId;
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();
    const fcmToken = userDoc.get("fcmToken");
    if (!fcmToken) return null;

    let threshold = null;
    if (spent >= 0.9 * amount && (!before || before.spent < 0.9 * amount)) {
      threshold = 90;
    } else if (
      spent >= 0.5 * amount &&
      (!before || before.spent < 0.5 * amount)
    ) {
      threshold = 50;
    }

    if (!threshold) return null;

    const message = {
      notification: {
        title: "Budget Alert",
        body: `You have reached ${threshold}% of your monthly budget.`,
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    return null;
  });
