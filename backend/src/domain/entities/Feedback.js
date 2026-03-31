// The Feedback entity represents a user's feedback, error report, or improvement idea.
class Feedback {
  constructor({
    id,
    ownerId,
    ownerName,
    category,
    message,
    createdAt,
  }) {
    this.id = id;
    this.ownerId = ownerId;
    this.ownerName = ownerName || 'Unknown User';
    this.category = category; // 'Feedback', 'Error', 'Improvement'
    this.message = message;
    this.createdAt = createdAt || new Date().toISOString();
  }

  // Converts this class instance back into a plain JSON object
  toJSON() {
    return {
      id: this.id,
      ownerId: this.ownerId,
      ownerName: this.ownerName,
      category: this.category,
      message: this.message,
      createdAt: this.createdAt,
    };
  }
}

module.exports = Feedback;
