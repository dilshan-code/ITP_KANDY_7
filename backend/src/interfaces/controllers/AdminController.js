// AdminController handles administrative tasks, such as managing the shop owners.
class AdminController {
    constructor({ getAllOwners, updateOwnerProfile, deleteOwner, getOwnerProfile, getSystemHealth }) {
        this.getAllOwners = getAllOwners;
        this.updateOwnerProfile = updateOwnerProfile;
        this.deleteOwner = deleteOwner;
        this.getOwnerProfile = getOwnerProfile;
        this.getSystemHealth = getSystemHealth;
    }

    // Fetches real-time system health and database statistics.
    async getSystemHealthStats(req, res) {
        try {
            const health = await this.getSystemHealth.execute();
            res.json({ success: true, data: health });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Fetches a list of all shop owners registered in the system.
    async getOwners(req, res) {
        try {
            const owners = await this.getAllOwners.execute();
            res.json({ success: true, data: owners });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async updateOwner(req, res) {
        try {
            const owner = await this.updateOwnerProfile.execute(req.params.id, req.body);
            if (!owner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, data: owner });
        } catch (error) {
            const statusCode = error.message.includes('already uses') || error.message.includes('Invalid owner status')
                ? 400
                : 500;
            res.status(statusCode).json({ success: false, error: error.message });
        }
    }

    async suspendOwner(req, res) {
        try {
            // First, fetch the current owner to determine their suspension status.
            const existingOwner = await this.getOwnerProfile.execute(req.params.id);
            if (!existingOwner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }

            // Determine the new toggle state. If they are currently suspended, we unsuspend them.
            const currentlySuspended = existingOwner.isSuspended || existingOwner.status === 'suspended';
            const willBeSuspended = !currentlySuspended;

            const owner = await this.updateOwnerProfile.execute(req.params.id, {
                status: willBeSuspended ? 'suspended' : 'approved',
                isSuspended: willBeSuspended,
            });

            res.json({ success: true, data: owner });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async deleteOwnerRecord(req, res) {
        try {
            const deleted = await this.deleteOwner.execute(req.params.id);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, message: 'Owner deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = AdminController;
