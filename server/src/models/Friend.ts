import mongoose from "mongoose";

// A "friend" is a unidirectional follow: userId follows friendId.
// To be mutual friends, both directions must exist.
const friendSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    friendId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  { timestamps: true }
);

// Ensure each (userId, friendId) pair is unique
friendSchema.index({ userId: 1, friendId: 1 }, { unique: true });

export default mongoose.model("Friend", friendSchema, "friends");
