const cron = require('node-cron');
const { checkLowStock } = require('./services/stockMonitor');
const { checkCreditOverdue } = require('./services/creditMonitor');

console.log('🚀 Notification backend started...');

checkLowStock();
checkCreditOverdue();

cron.schedule('*/5 * * * *', () => {
  console.log('\n⏰ Running scheduled checks...');
  checkLowStock();
  checkCreditOverdue();
});

cron.schedule('0 8 * * *', () => {
  console.log('\n🌅 Running daily morning checks...');
  checkLowStock();
  checkCreditOverdue();
});

console.log('✅ Scheduler running — checks every 5 minutes');