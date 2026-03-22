const { db } = require('../config/firebase');

async function createNotification({
  type,
  category,
  title,
  message,
  relatedId = null,
  amount = null,
  daysOverdue = null,
  severity = 'medium'
}) {
  try {
    const notifRef = db.ref('notifications');
    await notifRef.push({
      type,
      category,
      title,
      message,
      isRead: false,
      timestamp: Date.now(),
      relatedId,
      amount,
      daysOverdue,
      severity,
      createdBy: 'system'
    });
    console.log(`✅ Notification created: ${title}`);
  } catch (error) {
    console.error('❌ Error creating notification:', error);
  }
}

module.exports = { createNotification };
