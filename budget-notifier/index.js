const admin = require("firebase-admin");
const fetch = require("node-fetch");
const serviceAccount = require("./service-account.json");

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Replace with your OneSignal App ID and REST API Key
const ONESIGNAL_APP_ID = "ff4ab613-8e47-4610-9d1b-ec316d008b48";
const ONESIGNAL_API_KEY =
  "os_v2_org_zxmudvrc7zdyzdnqebqqzemtg5keivurhgluzwuijha65ifvwsrdvcnurovmwc7ngzta2dssvk3s4sjgftimb4rkthj657d7hwlw2fy";

// Main function to check budgets and send notifications
async function checkBudgetsAndNotify() {
  const usersSnapshot = await db.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const budgetsSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("budgets")
      .get();
    for (const budgetDoc of budgetsSnapshot.docs) {
      const data = budgetDoc.data();
      if (!data.amount || !data.spent) continue;

      // Check for 90% threshold
      if (data.spent >= 0.9 * data.amount && !data.notified90) {
        await sendNotification(userDoc, 90);
        await budgetDoc.ref.update({ notified90: true });
      }
      // Check for 50% threshold
      else if (data.spent >= 0.5 * data.amount && !data.notified50) {
        await sendNotification(userDoc, 50);
        await budgetDoc.ref.update({ notified50: true });
      }
    }
  }
}

// Function to send notification via OneSignal
async function sendNotification(userDoc, threshold) {
  const oneSignalId = userDoc.get("oneSignalId");
  if (!oneSignalId) {
    console.log(`No OneSignal ID for user ${userDoc.id}`);
    return;
  }

  const body = {
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: [oneSignalId],
    headings: { en: "Budget Alert" },
    contents: { en: `You have reached ${threshold}% of your monthly budget.` },
  };

  const response = await fetch("https://onesignal.com/api/v1/notifications", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Basic ${ONESIGNAL_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  if (response.ok) {
    console.log(
      `Notification sent to user ${userDoc.id} for ${threshold}% threshold.`
    );
  } else {
    const error = await response.text();
    console.error(`Failed to send notification: ${error}`);
  }
}

// Run the check every 5 minutes
setInterval(checkBudgetsAndNotify, 5 * 60 * 1000);

// Run immediately on start
checkBudgetsAndNotify();
