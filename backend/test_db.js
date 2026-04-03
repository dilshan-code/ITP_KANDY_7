require('dotenv').config();
const mongoose = require('mongoose');

async function testMongo() {
    console.log('Testing MongoDB connection...');
    const uri = process.env.MONGODB_URI;
    if (!uri) {
        console.error('MONGODB_URI not found in .env');
        process.exit(1);
    }

    try {
        await mongoose.connect(uri);
        console.log('✅ Successfully connected to MongoDB Atlas!');
        await mongoose.connection.close();
        process.exit(0);
    } catch (error) {
        console.error('❌ Failed to connect to MongoDB Atlas:', error.message);
        process.exit(1);
    }
}

testMongo();
