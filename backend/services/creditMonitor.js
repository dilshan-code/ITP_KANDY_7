const { db } = require('../config/firebase');
const { createNotification } = require('../helpers/notificationHelper');

async function checkCreditOverdue() {
  console.log('🔍 Checking credit balances...');

  try {
    const snapshot = await db.ref('customers').once('value');
    const customers = snapshot.val();

    if (!customers) {
      console.log('No customers found in database.');
      return;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (const [customerId, customer] of Object.entries(customers)) {
      if (!customer.creditBalance || customer.creditBalance <= 0) continue;

      const dueDate = new Date(customer.dueDate);
      dueDate.setHours(0, 0, 0, 0);

      const diffTime = today - dueDate;
      const daysOverdue = Math.floor(diffTime / (1000 * 60 * 60 * 24));

      if (daysOverdue > 0) {
        const existingSnapshot = await db.ref('notifications')
          .orderByChild('relatedId')
          .equalTo(customerId)
          .once('value');

        const existing = existingSnapshot.val();
        const alreadyNotified = existing && Object.values(existing)
          .some(n => n.type === 'credit' && !n.isRead);

        if (!alreadyNotified) {
          await createNotification({
            type: 'credit',
            category: 'Credit',
            title: '⚠️ Credit Overdue',
            message: `${customer.name} owes LKR ${customer.creditBalance.toLocaleString()} — ${daysOverdue} day${daysOverdue > 1 ? 's' : ''} overdue.`,
            relatedId: customerId,
            amount: customer.creditBalance,
            daysOverdue: daysOverdue,
            severity: daysOverdue >= 7 ? 'high' : daysOverdue >= 3 ? 'medium' : 'low'
          });

          await db.ref(`customers/${customerId}`).update({ isOverdue: true });
        }
      }
    }
  } catch (error) {
    console.error('❌ Credit check error:', error);
  }
}

module.exports = { checkCreditOverdue };