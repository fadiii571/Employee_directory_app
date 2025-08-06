
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendCheckInOutNotification = functions.firestore
  .document("attendance/{date}/records/{employeeId}")
  .onWrite(async (change, context) => {
    const data = change.after.exists ? change.after.data() : null;
    if (!data) return;

    const logs = data.logs || [];
    if (logs.length === 0) return;

    const latestLog = logs[logs.length - 1]; // get latest check-in or check-out
    const logType = latestLog.type === "in" ? "Check-In" : "Check-Out";
    const employeeName = data.name || "An employee";
    const time = latestLog.time || "";

    // Fetch admin FCM token from Firestore
    const adminDoc = await admin.firestore().collection("admin").doc("fcmToken").get();
    const fcmToken = adminDoc.exists ? adminDoc.data().token : null;

    if (!fcmToken) return;

    const payload = {
      notification: {
        title: `${employeeName} ${logType}`,
        body: `Time: ${time}`,
      },
      token: fcmToken,
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log("Notification sent successfully:", response);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
