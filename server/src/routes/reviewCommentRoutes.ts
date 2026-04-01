import { Router, Response } from "express";
import ReviewComment from "../models/ReviewComment";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// Get all comments for a review
router.get("/:reviewId", async (req: AuthRequest, res: Response) => {
	try {
		const comments = await ReviewComment.find({ reviewId: req.params.reviewId }).populate(
			"authorUserId",
			"username email"
		);
		res.status(200).json(comments);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch comments", error });
	}
});

// Add a comment to a review
router.post("/", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { reviewId, commentText } = req.body;
		const authorUserId = req.user?.id;

		if (!reviewId || !commentText || !authorUserId) {
			return res.status(400).json({ message: "Missing required fields" });
		}

		const newComment = new ReviewComment({
			reviewId,
			authorUserId,
			commentText,
		});

		await newComment.save();
		await newComment.populate("authorUserId", "username email");
		res.status(201).json({ message: "Comment added", data: newComment });
	} catch (error) {
		res.status(500).json({ message: "Failed to add comment", error });
	}
});

export default router;
