const bcrypt = require('bcryptjs');

// This helper ensures phone numbers are always in a consistent format (+94XX...).
// It converts numbers starting with '0' to the international '+94' format.
function normalizePhone(phone) {
    if (!phone) return phone;
    const trimmed = phone.trim();
    // If it's a standard 10-digit local number (07xxxxxxxx), convert it.
    if (trimmed.startsWith('0') && trimmed.length === 10) {
        return '+94' + trimmed.substring(1);
    }
    return trimmed;
}


// This use case handles the registration of a new shop owner.
class RegisterOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(ownerData) {
        const normalizedPhone = normalizePhone(ownerData.phone);
        
        // Check if email already exists, if provided
        if (ownerData.email) {
            const existingEmail = await this.ownerRepository.findByEmail(ownerData.email);
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
        return this.ownerRepository.create({ ...ownerData, phone: normalizedPhone, password: hashedPassword });
    }
}

// This use case handles the login process for an existing owner.
class LoginOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    // Checks if the email or phone and password match a record in the database.
    async execute(identifier, password) {
        let owner;
        if (identifier && identifier.includes('@')) {
            owner = await this.ownerRepository.findByEmail(identifier);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }
        
        if (!owner) {
            throw new Error('Invalid email/phone or password');
        }
        const isMatch = await bcrypt.compare(password, owner.password);
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
        // Do not allow updating password through this use case
        const { password, ...updateData } = profileData;
        
        if (updateData.phone) {
            updateData.phone = normalizePhone(updateData.phone);
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
        // Step 1: Fetch the owner's raw record directly from Firestore.
        // We do this because the standard repository 'getById' might strip out the encrypted password.
        const rawOwner = await this.ownerRepository.collection.doc(id).get();
        if (!rawOwner.exists) {
            throw new Error('Owner not found');
        }
        const ownerData = rawOwner.data();
        
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

module.exports = { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword, GetAllOwners };
