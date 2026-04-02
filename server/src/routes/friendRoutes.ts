import { Router, Response } from "express";
import Friend from "../models/Friend";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// GET /api/friends
// Returns the list of users the current user follows.
router.get("/", authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const friends = await Friend.find({ userId })
      .populate("friendId", "username profileVisibility")
      .lean();

    const result = friends.map((f: any) => ({
      _id: f.friendId._id,
      username: f.friendId.username,
      profileVisibility: f.friendId.profileVisibility,
    }));

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch friends", error });
  }
});

// POST /api/friends/:friendId
// Follow a user (add as friend).
router.post("/:friendId", authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const { friendId } = req.params;

    if (userId === friendId) {
      return res.status(400).json({ message: "You cannot follow yourself" });
    }

    const existing = await Friend.findOne({ userId, friendId });
    if (existing) {
      return res.status(400).json({ message: "Already following this user" });
    }

    await Friend.create({ userId: String(userId), friendId: String(friendId) });
    res.status(201).json({ message: "Now following user" });
  } catch (error) {
    res.status(500).json({ message: "Failed to follow user", error });
  }
});

// DELETE /api/friends/:friendId
// Unfollow a user.
router.delete("/:friendId", authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const { friendId } = req.params;

    const deleted = await Friend.findOneAndDelete({ userId, friendId });
    if (!deleted) {
      return res.status(404).json({ message: "Not following this user" });
    }

    res.json({ message: "Unfollowed user" });
  } catch (error) {
    res.status(500).json({ message: "Failed to unfollow user", error });
  }
});

// GET /api/friends/check/:friendId
// Check if the current user follows a specific user.
router.get("/check/:friendId", authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const { friendId } = req.params;
    const existing = await Friend.findOne({ userId, friendId });
    res.json({ following: !!existing });
  } catch (error) {
    res.status(500).json({ message: "Failed to check follow status", error });
  }
});

export default router;
