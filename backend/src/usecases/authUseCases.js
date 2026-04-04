const bcrypt = require('bcryptjs');
const { isValidEmail, isValidPhone, isValidPassword } = require('../utils/validationUtils');

// This helper ensures phone numbers are always in a consistent format (+94XX...).
// It removes all non-digit characters (except the leading +) and converts numbers 
// starting with '0' to the international '+94' format.
function normalizePhone(phone) {
    if (!phone) return phone;
    // Remove all non-digit characters except for a leading '+'
    const clean = phone.trim().replace(/(?!^\+)\D/g, '');
    
    // If it's a standard 10-digit local number (07xxxxxxxx), convert it.
    if (clean.startsWith('0') && clean.length === 10) {
        return '+94' + clean.substring(1);
    }
    return clean;
}

function normalizeEmail(email) {
    if (!email) return '';
    return email.trim().toLowerCase();
}


// This use case handles the registration of a new shop owner.
class RegisterOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(ownerData) {
        // Validation Checks
        if (!ownerData.name || ownerData.name.trim() === '') {
            throw new Error('Owner name is required');
        }
        if (!ownerData.shopName || ownerData.shopName.trim() === '') {
            throw new Error('Shop name is required');
        }
        if (!isValidPhone(ownerData.phone)) {
            throw new Error('Valid phone number is required (start with 0 or +94 and have 9 digits after)');
        }
        if (ownerData.email && !isValidEmail(ownerData.email)) {
            throw new Error('Email must end with @gmail.com');
        }
        if (!isValidPassword(ownerData.password)) {
            throw new Error('Password must be at least 8 characters long');
        }

        const normalizedPhone = normalizePhone(ownerData.phone);
        const normalizedEmail = normalizeEmail(ownerData.email);
        
        // Check if email already exists, if provided
        if (normalizedEmail) {
            const existingEmail = await this.ownerRepository.findByEmail(normalizedEmail);
            if (existingEmail) {
                throw new Error('An account with this email already exists');
            }
        }
        // Check if phone already exists
        if (normalizedPhone) {
            const existingPhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (existingPhone) {
                throw new Error('An account with this phone number already exists');
            }
        }
        // Hash the password before saving
        const hashedPassword = await bcrypt.hash(ownerData.password, 10);
        return this.ownerRepository.create({ 
            ...ownerData, 
            phone: normalizedPhone, 
            email: normalizedEmail, 
            password: hashedPassword,
            status: 'approved',
            isSuspended: false
        });
    }
}

// This use case handles the login process for an existing owner.
class LoginOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    // Checks if the email or phone and password match a record in the database.
    async execute(identifier, password) {
        console.log(`[LOGIN] Attempt for: ${identifier}`);
        let owner;
        if (identifier && identifier.includes('@')) {
            const normalizedEmail = normalizeEmail(identifier);
            console.log(`[LOGIN] Finding by email: ${normalizedEmail}`);
            owner = await this.ownerRepository.findByEmail(normalizedEmail);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            console.log(`[LOGIN] Finding by phone: ${normalizedPhone}`);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }
        
        if (!owner) {
            console.log(`[LOGIN] User NOT found: ${identifier}`);
            throw new Error('Invalid email/phone or password');
        }

        if (owner.isSuspended || owner.status === 'suspended') {
            throw new Error('Your account has been suspended. Please contact admin.');
        }

        console.log(`[LOGIN] User found, comparing password.`);
        let isMatch = await bcrypt.compare(password, owner.password);
        
        console.log(`[LOGIN] Password match: ${isMatch}`);
        if (!isMatch) {
            throw new Error('Invalid email/phone or password');
        }
        // Return owner data without password
        const { password: _, ...ownerData } = owner;
        return ownerData;
    }
}

class UpdateOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id, profileData) {
        const updateData = { ...profileData };
        
        // Handle password update if provided
        if (updateData.password && updateData.password.trim() !== '') {
            if (!isValidPassword(updateData.password)) {
                throw new Error('Password must be at least 8 characters long');
            }
            updateData.password = await bcrypt.hash(updateData.password, 10);
        } else {
            // Remove empty or missing password from update payload
            delete updateData.password;
        }
        
        if (updateData.phone) {
            if (!isValidPhone(updateData.phone)) {
                throw new Error('Valid phone number is required (start with 0 or +94 and have 9 digits after)');
            }
            updateData.phone = normalizePhone(updateData.phone);
        }

        if (updateData.email) {
            updateData.email = normalizeEmail(updateData.email);
        }
        
        return this.ownerRepository.update(id, updateData);
    }
}

// This use case allows an owner to change their account password.
class ChangeOwnerPassword {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id, oldPassword, newPassword) {
        // Step 1: Fetch the owner's raw record including the password hash via the repository.
        const owner = await this.ownerRepository.getByIdWithPassword(id);
        if (!owner) {
            throw new Error('Owner not found');
        }
        const ownerData = owner; // This is an Owner instance with password
        
        // Step 2: Verify that the 'old password' provided matches the one in our database.
        const isMatch = await bcrypt.compare(oldPassword, ownerData.password);
        if (!isMatch) {
            throw new Error('Current password does not match');
        }
        
        // Step 3: Hash the new password before saving it for security.
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        // Step 4: Persist the new hashed password.
        return this.ownerRepository.update(id, { password: hashedNewPassword });
    }
}

class ResetPassword {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(identifier, newPassword) {
        let owner;
        if (identifier && identifier.includes('@')) {
            const normalizedEmail = normalizeEmail(identifier);
            owner = await this.ownerRepository.findByEmail(normalizedEmail);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }

        if (!owner) {
            throw new Error('User not found with this email/phone');
        }

        if (!isValidPassword(newPassword)) {
            throw new Error('Password must be at least 8 characters long');
        }

        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        return this.ownerRepository.update(owner.id || owner._id, { password: hashedNewPassword });
    }
}

class GetOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id) {
        return this.ownerRepository.getById(id);
    }
}

class GetAllOwners {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute() {
        return this.ownerRepository.getAll();
    }
}

class UpdateOwnerByAdmin {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute(id, ownerData) {
        const existingOwner = await this.ownerRepository.getByIdWithPassword(id);
        if (!existingOwner) {
            return null;
        }

        const allowedStatusValues = new Set(['approved', 'suspended']);
        const normalizedEmail = typeof ownerData.email === 'string'
            ? ownerData.email.trim().toLowerCase()
            : existingOwner.email;
        const normalizedPhone = typeof ownerData.phone === 'string'
            ? ownerData.phone.trim()
            : existingOwner.phone;

        if (normalizedEmail) {
            const ownerWithSameEmail = await this.ownerRepository.findByEmail(normalizedEmail);
            if (ownerWithSameEmail && (ownerWithSameEmail.id !== id && ownerWithSameEmail._id !== id)) {
                throw new Error('Another account already uses this email address');
            }
        }

        if (normalizedPhone) {
            const ownerWithSamePhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (ownerWithSamePhone && (ownerWithSamePhone.id !== id && ownerWithSamePhone._id !== id)) {
                throw new Error('Another account already uses this phone number');
            }
        }

        let normalizedStatus = ownerData.status;
        if (typeof normalizedStatus === 'string') {
            normalizedStatus = normalizedStatus.trim().toLowerCase();
            if (!allowedStatusValues.has(normalizedStatus)) {
                throw new Error('Invalid owner status');
            }
        }

        let normalizedSuspension = ownerData.isSuspended;
        if (normalizedStatus === 'approved') normalizedSuspension = false;
        if (normalizedStatus === 'suspended') normalizedSuspension = true;
        
        if (normalizedSuspension === false && normalizedStatus == null && existingOwner.status === 'suspended') {
            normalizedStatus = 'approved';
        }
        if (normalizedSuspension === true && normalizedStatus == null) {
            normalizedStatus = 'suspended';
        }

        const updateData = {
            name: typeof ownerData.name === 'string' ? ownerData.name.trim() : existingOwner.name,
            shopName: typeof ownerData.shopName === 'string' ? ownerData.shopName.trim() : existingOwner.shopName,
            phone: normalizedPhone,
            email: normalizedEmail || '',
            status: normalizedStatus ?? existingOwner.status,
            isSuspended: typeof normalizedSuspension === 'boolean'
                ? normalizedSuspension
                : existingOwner.isSuspended,
        };

        if (ownerData.password && ownerData.password.trim() !== '') {
            if (!isValidPassword(ownerData.password)) {
                throw new Error('Password must be at least 8 characters long');
            }
            updateData.password = await bcrypt.hash(ownerData.password, 10);
        }

        return this.ownerRepository.update(id, updateData);
    }
}

class DeleteOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id) {
        return this.ownerRepository.delete(id);
    }
}

module.exports = { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword, GetAllOwners, ResetPassword, UpdateOwnerByAdmin, DeleteOwner };
