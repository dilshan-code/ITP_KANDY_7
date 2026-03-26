const mongoose = require('mongoose');
require('dotenv').config();

// This function establishes a secure link between our application and the MongoDB database.
const connectDB = async () => {
    try {
        // Attempt to connect using the URI provided in the environment variables.
        const conn = await mongoose.connect(process.env.MONGODB_URI);
        console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        // If the connection fails, log the error and stop the server to prevent data inconsistencies.
        console.error(`❌ MongoDB Connection Error: ${error.message}`);
        process.exit(1);
    }
};

module.exports = connectDB;
