// AdminController handles administrative tasks, such as managing the shop owners.
class AdminController {
    constructor({ getAllOwners }) {
        this.getAllOwners = getAllOwners;
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
}

module.exports = AdminController;
