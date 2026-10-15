"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyGroupAnnouncement = exports.notifyLostPilgrim = exports.notifyGroupMessage = exports.notifyDirectMessage = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const firestore_2 = require("firebase-functions/v2/firestore");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const messaging = (0, messaging_1.getMessaging)();
async function sendToUsers(userIds, title, body, data) {
    const uniqueIds = [...new Set(userIds)];
    const tokenSnapshots = await Promise.all(uniqueIds.map((uid) => db.collection("users").doc(uid).collection("fcm_tokens").get()));
    const tokens = tokenSnapshots.flatMap((snapshot) => snapshot.docs.map((doc) => ({ uid: doc.ref.parent.parent.id, doc, token: doc.get("token") }))).filter((item) => item.token);
    for (let offset = 0; offset < tokens.length; offset += 500) {
        const batch = tokens.slice(offset, offset + 500);
        const result = await messaging.sendEachForMulticast({
            tokens: batch.map((item) => item.token),
            notification: { title, body },
            data,
            android: {
                priority: "high",
                notification: { channelId: "rifqa_messages", sound: "default" },
            },
            apns: { payload: { aps: { sound: "default", interruptionLevel: "active" } } },
        });
        const staleTokens = batch.filter((_, index) => {
            const code = result.responses[index].error?.code;
            return code === "messaging/invalid-registration-token" ||
                code === "messaging/registration-token-not-registered";
        });
        await Promise.all(staleTokens.map((item) => item.doc.ref.delete()));
    }
}
exports.notifyDirectMessage = (0, firestore_2.onDocumentCreated)("direct_chats/{chatId}/messages/{messageId}", async (event) => {
    const message = event.data?.data();
    if (!message)
        return;
    const chat = await db.collection("direct_chats").doc(event.params.chatId).get();
    const participants = chat.get("participantIds") ?? [];
    const senderId = String(message.senderId ?? "");
    const senderName = String(message.senderName ?? "صديق");
    const messageType = String(message.type ?? "text");
    const body = messageType === "image"
        ? "أرسل صورة"
        : messageType === "voice"
            ? "أرسل رسالة صوتية"
            : String(message.text ?? "أرسل رسالة");
    await sendToUsers(participants.filter((uid) => uid !== senderId), senderName, body, {
        type: "direct_message",
        chatId: event.params.chatId,
        friendUid: senderId,
        friendName: senderName,
    });
});
exports.notifyGroupMessage = (0, firestore_2.onDocumentCreated)("groups/{groupId}/messages/{messageId}", async (event) => {
    const message = event.data?.data();
    if (!message)
        return;
    const group = await db.collection("groups").doc(event.params.groupId).get();
    const members = group.get("memberIds") ?? [];
    const senderId = String(message.senderId ?? "");
    const senderName = String(message.senderName ?? "عضو");
    const type = String(message.type ?? "text");
    await sendToUsers(members.filter((uid) => uid !== senderId), `${senderName} · ${String(group.get("name") ?? "المجموعة")}`, type === "text"
        ? String(message.text ?? "أرسل رسالة")
        : type === "image"
            ? "أرسل صورة للمجموعة"
            : type === "voice"
                ? "أرسل رسالة صوتية للمجموعة"
                : "أرسل موقعًا للمجموعة", { type: "group_message", groupId: event.params.groupId });
});
exports.notifyLostPilgrim = (0, firestore_2.onDocumentCreated)("groups/{groupId}/alerts/{alertId}", async (event) => {
    const alert = event.data?.data();
    if (!alert)
        return;
    const group = await db.collection("groups").doc(event.params.groupId).get();
    const members = group.get("memberIds") ?? [];
    const senderId = String(alert.senderId ?? "");
    await sendToUsers(members.filter((uid) => uid !== senderId), "بلاغ استغاثة: أحد أفراد المجموعة تائه", `${String(alert.senderName ?? "أحد الأعضاء")} يحتاج إلى المساعدة. افتحي المجموعة لمشاهدة موقعه.`, { type: "lost_pilgrim", groupId: event.params.groupId, alertId: event.params.alertId });
});
exports.notifyGroupAnnouncement = (0, firestore_2.onDocumentCreated)("groups/{groupId}/announcements/{announcementId}", async (event) => {
    const announcement = event.data?.data();
    if (!announcement)
        return;
    const group = await db.collection("groups").doc(event.params.groupId).get();
    const members = group.get("memberIds") ?? [];
    const senderId = String(announcement.senderId ?? "");
    await sendToUsers(members.filter((uid) => uid !== senderId), `إعلان المشرف · ${String(group.get("name") ?? "المجموعة")}`, String(announcement.text ?? "تم نشر إعلان جديد"), { type: "group_announcement", groupId: event.params.groupId });
});
