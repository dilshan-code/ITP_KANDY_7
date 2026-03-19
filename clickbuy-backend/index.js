const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const cors = require('cors');
const PDFDocument = require('pdfkit');

//comment

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://studio-1424340345-c4815-default-rtdb.asia-southeast1.firebasedatabase.app/'
});

const app = express();
app.use(bodyParser.json());
app.use(cors());

const db = admin.database();

// Input validation middleware
const validateCreditInput = (req, res, next) => {
  const { creditLimit, currentBalance, unpaidBalance } = req.body;
  if (!creditLimit || !currentBalance || !unpaidBalance) {
    return res.status(400).send('Missing required fields');
  }
  if (isNaN(creditLimit) || isNaN(currentBalance) || isNaN(unpaidBalance)) {
    return res.status(400).send('Invalid number format');
  }
  next();
};

const verifyToken = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];
  if (!token) return res.status(401).send('Unauthorized');
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.userId = decoded.uid;
    next();
  } catch (err) {
    res.status(401).send('Invalid token');
  }
};

// Check if admin middleware
const isAdmin = async (req, res, next) => {
  const userRef = db.ref(`users/${req.userId}/role`);
  userRef.once('value').then(snapshot => {
    if (snapshot.val() === 'admin') next();
    else res.status(403).send('Admin access required');
  }).catch(err => res.status(500).send(err.message));
};

// Get user role
app.get('/user/role', verifyToken, (req, res) => {
  const userRef = db.ref(`users/${req.userId}/role`);
  userRef.once('value')
    .then(snapshot => res.json({ role: snapshot.val() || 'customer' }))
    .catch(err => res.status(500).send(err.message));
});

// CREATE: Add credit details (initial setup for a user)
app.post('/credit', verifyToken, validateCreditInput, (req, res) => {
  const { creditLimit, currentBalance, unpaidBalance } = req.body;
  const ref = db.ref(`users/${req.userId}/creditDetails`);
  ref.set({
    creditLimit,
    currentBalance,
    unpaidBalance,
    paymentHistory: []
  })
  .then(() => res.send('Credit details added'))
  .catch(err => res.status(500).send(err.message));
});

// READ: View balances and history
app.get('/credit', verifyToken, (req, res) => {
  const ref = db.ref(`users/${req.userId}/creditDetails`);
  ref.once('value')
  .then(snapshot => res.json(snapshot.val() || {}))
  .catch(err => res.status(500).send(err.message));
});

// UPDATE: Record a payment (add to history and update balances)
app.put('/credit/payment', verifyToken, (req, res) => {
  const { amount, status } = req.body;
  if (!amount || amount <= 0) {
    return res.status(400).send('Invalid amount');
  }
  
  const date = new Date().toISOString();
  const ref = db.ref(`users/${req.userId}/creditDetails`);
  
  ref.transaction(data => {
    if (!data) {
      return { 
        paymentHistory: [{ date, amount, status }], 
        unpaidBalance: -amount, 
        currentBalance: amount,
        creditLimit: 0
      };
    }
    data.paymentHistory = data.paymentHistory || [];
    data.paymentHistory.push({ date, amount, status });
    data.unpaidBalance = (data.unpaidBalance || 0) - amount;
    data.currentBalance = (data.currentBalance || 0) + amount;
    return data;
  })
  .then(result => {
    if (result.committed) {
      res.send('Payment recorded');
    } else {
      res.status(500).send('Transaction failed');
    }
  })
  .catch(err => res.status(500).send(err.message));
});

// DELETE: Remove credit records (clears all for the user)
app.delete('/credit', verifyToken, (req, res) => {
  const ref = db.ref(`users/${req.userId}/creditDetails`);
  ref.remove()
  .then(() => res.send('Credit records removed'))
  .catch(err => res.status(500).send(err.message));
});

app.post('/init-credit', verifyToken, (req, res) => {
  const ref = db.ref(`users/${req.userId}`);
  ref.child('role').set('customer');  // Default role
  ref.child('creditDetails').set({
    creditLimit: 5000,
    currentBalance: 5000,
    unpaidBalance: 0,
    paymentHistory: []
  }).then(() => res.send('Initial credits set'))
    .catch(err => res.status(500).send(err.message));
});

// CREATE Order - Updated to handle unpaid balance correctly
app.post('/order', verifyToken, (req, res) => {
  const { items, total, paymentMethod, cashPaid = 0, creditsUsed = 0 } = req.body;
  const orderId = db.ref(`users/${req.userId}/orders`).push().key;
  const orderRef = db.ref(`users/${req.userId}/orders/${orderId}`);
  const date = new Date().toISOString();
  
  // Create order object
  const orderData = { 
    items, 
    total, 
    paymentMethod, 
    cashPaid, 
    creditsUsed, 
    date,
    orderNumber: orderId.substring(0, 8).toUpperCase()
  };
  
  orderRef.set(orderData);

  // Update credit details if credits were used
  if (creditsUsed > 0) {
    const creditRef = db.ref(`users/${req.userId}/creditDetails`);
    creditRef.transaction(data => {
      if (data) {
        // Deduct from current balance
        data.currentBalance = (data.currentBalance || 0) - creditsUsed;
        
        // Add to unpaid balance (since customer is using credit)
        data.unpaidBalance = (data.unpaidBalance || 0) + creditsUsed;
        
        // Add to payment history
        data.paymentHistory = data.paymentHistory || [];
        data.paymentHistory.push({ 
          date, 
          amount: -creditsUsed, 
          status: 'used for order',
          orderId: orderId
        });
      }
      return data;
    });
  }

  res.json({ 
    message: 'Order placed', 
    orderId: orderId,
    orderNumber: orderData.orderNumber 
  });
});

// READ Orders (for customer history)
app.get('/orders', verifyToken, (req, res) => {
  const ref = db.ref(`users/${req.userId}/orders`);
  ref.once('value').then(snapshot => res.json(snapshot.val() || {}))
    .catch(err => res.status(500).send(err.message));
});

// Get single order details for PDF generation
app.get('/order/:orderId', verifyToken, (req, res) => {
  const orderId = req.params.orderId;
  const ref = db.ref(`users/${req.userId}/orders/${orderId}`);
  ref.once('value')
    .then(snapshot => {
      if (snapshot.exists()) {
        res.json(snapshot.val());
      } else {
        res.status(404).send('Order not found');
      }
    })
    .catch(err => res.status(500).send(err.message));
});

// Generate PDF receipt for an order
app.get('/order/:orderId/pdf', verifyToken, async (req, res) => {
  try {
    const orderId = req.params.orderId;
    const orderRef = db.ref(`users/${req.userId}/orders/${orderId}`);
    const orderSnapshot = await orderRef.once('value');

    if (!orderSnapshot.exists()) {
      return res.status(404).send('Order not found');
    }

    const order = orderSnapshot.val();
    const userEmail = (await admin.auth().getUser(req.userId)).email;

    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument({
      margin: 50,
      size: 'A4',
      bufferPages: true
    });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename=order_${order.orderNumber || orderId}.pdf`
    );

    doc.pipe(res);

    const pageWidth = doc.page.width;
    const pageHeight = doc.page.height;

    /* =====================================================
       HEADER
    ===================================================== */

    doc
      .fontSize(22)
      .font('Helvetica-Bold')
      .text('CLICKBUY STORE', { align: 'center' });

    doc
      .fontSize(10)
      .font('Helvetica')
      .text('123 Main Street, Colombo', { align: 'center' })
      .text('Tel: +94 11 234 5678 | Email: info@clickbuy.com', {
        align: 'center'
      });

    doc.moveDown(1.5);

    /* =====================================================
       RECEIPT TITLE
    ===================================================== */

    doc
      .fontSize(18)
      .font('Helvetica-Bold')
      .text('PAYMENT RECEIPT', { align: 'center' });

    doc.moveDown(1);

    doc
      .moveTo(50, doc.y)
      .lineTo(pageWidth - 50, doc.y)
      .stroke();

    doc.moveDown(1);

    /* =====================================================
       ORDER INFO
    ===================================================== */

    doc.fontSize(10).font('Helvetica');

    doc.text(`Receipt No: ${order.orderNumber || orderId.slice(0, 8).toUpperCase()}`);
    doc.text(`Date: ${new Date(order.date).toLocaleString()}`);
    doc.text(`Customer: ${userEmail}`);
    doc.text(`Payment Method: ${(order.paymentMethod || 'card').toUpperCase()}`);

    doc.moveDown(1.5);

    /* =====================================================
       TABLE SETUP
    ===================================================== */

    const tableTop = doc.y;
    const col1 = 50;
    const col2 = 300;
    const col3 = 370;
    const col4 = 450;

    const rowHeight = 25;

    // Table Header Background
    doc
      .rect(col1, tableTop, pageWidth - 100, rowHeight)
      .fill('#f2f2f2');

    doc.fillColor('#000');

    doc.font('Helvetica-Bold').fontSize(10);
    doc.text('Item', col1 + 5, tableTop + 8);
    doc.text('Qty', col2, tableTop + 8);
    doc.text('Unit Price', col3, tableTop + 8);
    doc.text('Total', col4, tableTop + 8);

    doc.font('Helvetica');
    let positionY = tableTop + rowHeight;
    let subtotal = 0;

    /* =====================================================
       TABLE ROWS
    ===================================================== */

    if (order.items && Array.isArray(order.items)) {
      order.items.forEach((item) => {
        const quantity = item.quantity || 1;
        const itemTotal = item.price * quantity;
        subtotal += itemTotal;

        // Draw row border
        doc
          .rect(col1, positionY, pageWidth - 100, rowHeight)
          .stroke();

        doc.text(item.name, col1 + 5, positionY + 8);
        doc.text(quantity.toString(), col2, positionY + 8);
        doc.text(`LKR ${item.price.toFixed(2)}`, col3, positionY + 8);
        doc.text(`LKR ${itemTotal.toFixed(2)}`, col4, positionY + 8);

        positionY += rowHeight;
      });
    }

    doc.moveDown(2);

    /* =====================================================
       TOTALS SECTION
    ===================================================== */

    const totalsX = 350;
    let totalsY = positionY + 20;

    doc.fontSize(10);

    function drawTotalRow(label, value, bold = false) {
      if (bold) doc.font('Helvetica-Bold');
      else doc.font('Helvetica');

      doc.text(label, totalsX, totalsY);
      doc.text(`LKR ${value.toFixed(2)}`, totalsX + 120, totalsY, {
        width: 100,
        align: 'right'
      });

      totalsY += 20;
    }

    drawTotalRow('Subtotal:', subtotal);

    if (order.cashPaid > 0) {
      drawTotalRow('Cash Paid:', order.cashPaid);
    }

    if (order.creditsUsed > 0) {
      drawTotalRow('Credits Used:', order.creditsUsed);
    }

    const change =
      order.cashPaid > order.total
        ? order.cashPaid - order.total
        : 0;

    if (change > 0) {
      drawTotalRow('Change:', change);
    }

    doc
      .moveTo(totalsX, totalsY)
      .lineTo(pageWidth - 50, totalsY)
      .stroke();

    totalsY += 5;

    drawTotalRow('TOTAL:', order.total, true);

    /* =====================================================
       PAYMENT STATUS
    ===================================================== */

    doc.moveDown(2);

    let statusText = 'PAID BY CARD';

    if (order.paymentMethod === 'cash' && order.cashPaid >= order.total) {
      statusText =
        order.creditsUsed > 0
          ? 'PAID WITH CASH + CREDITS'
          : 'PAID IN FULL';
    } else if (order.creditsUsed > 0) {
      statusText = 'PAID WITH CREDITS';
    }

    doc
      .rect(150, doc.y, pageWidth - 300, 40)
      .fill('#f9f9f9');

    doc
      .fillColor('#000')
      .fontSize(14)
      .font('Helvetica-Bold')
      .text(statusText, 150, doc.y + 12, {
        width: pageWidth - 300,
        align: 'center'
      });

    doc.moveDown(3);

    /* =====================================================
       FOOTER
    ===================================================== */

    doc.fontSize(11).font('Helvetica');
    doc.text('Thank you for shopping with ClickBuy!', {
      align: 'center'
    });

    doc
      .fontSize(8)
      .fillColor('#777')
      .text('This is a computer generated receipt - no signature required', {
        align: 'center'
      });

    /* =====================================================
       DYNAMIC PAGE NUMBERS
    ===================================================== */

    const pageCount = doc.bufferedPageRange().count;

    for (let i = 0; i < pageCount; i++) {
      doc.switchToPage(i);
      doc
        .fontSize(8)
        .fillColor('#999')
        .text(
          `Page ${i + 1} of ${pageCount}`,
          0,
          pageHeight - 40,
          { align: 'center' }
        );
    }

    doc.end();
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).send('Error generating PDF');
  }
});

// Admin: Get all users and their details/credits
app.get('/admin/users', verifyToken, isAdmin, (req, res) => {
  const ref = db.ref('users');
  ref.once('value').then(snapshot => res.json(snapshot.val() || {}))
    .catch(err => res.status(500).send(err.message));
});

app.listen(3000, () => console.log('Server running on port 3000'));