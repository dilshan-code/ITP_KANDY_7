/**
 * Backend validation utilities for auth.
 */

const isValidEmail = (email) => {
    if (!email) return true; // Optional
    return email.toLowerCase().endsWith('@gmail.com');
};

const isValidPhone = (phone) => {
    if (!phone) return false; // Required
    const trimmed = phone.trim();
    // 0771234567 (10 digits) or +94771234567 (12 chars)
    return /^0[0-9]{9}$/.test(trimmed) || /^\+94[0-9]{9}$/.test(trimmed);
};

const isValidPassword = (password) => {
    return password && password.length >= 8;
};

// Ensures the provided price is a positive numeric value for products/sales.
const isValidPrice = (price) => {
    const val = parseFloat(price);
    // Use isNaN check and ensure it's strictly greater than zero.
    return !isNaN(val) && val > 0;
};

// Ensures stock levels are valid non-negative integers.
const isValidStock = (stock) => {
    // Initial null/undefined check for required inventory fields.
    if (stock === null || stock === undefined || stock === '') return false;
    const val = Number(stock);
    // Integers are required for discrete units (e.g. 1 item, 2 items).
    return Number.isInteger(val) && val >= 0;
};

module.exports = {
    isValidEmail,
    isValidPhone,
    isValidPassword,
    isValidPrice,
    isValidStock
};
