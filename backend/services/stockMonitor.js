const { db } = require('../config/firebase');
const { createNotification } = require('../helpers/notificationHelper');

async function checkLowStock() {
  console.log('🔍 Checking stock levels...');

  try {
    const snapshot = await db.ref('products').once('value');
    const products = snapshot.val();

    if (!products) {
      console.log('No products found in database.');
      return;
    }

    for (const [productId, product] of Object.entries(products)) {
      if (product.stock <= product.lowStockThreshold) {

        const existingSnapshot = await db.ref('notifications')
          .orderByChild('relatedId')
          .equalTo(productId)
          .once('value');

        const existing = existingSnapshot.val();
        const alreadyNotified = existing && Object.values(existing)
          .some(n => n.type === 'stock' && !n.isRead);

        if (!alreadyNotified) {
          await createNotification({
            type: 'stock',
            category: 'Stock',
            title: '📦 Low Stock Alert',
            message: `${product.name} — only ${product.stock} ${product.unit} remaining. Restock soon.`,
            relatedId: productId,
            severity: product.stock === 0 ? 'high' : 'medium'
          });
        }
      }
    }
  } catch (error) {
    console.error('❌ Stock check error:', error);
  }
}

module.exports = { checkLowStock };
