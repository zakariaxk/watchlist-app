import { Router, Response } from "express";
import Review from "../models/Comment";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// Get reviews for a media item (by imdbID)
router.get("/:imdbID", async (req: AuthRequest, res: Response) => {
	try {
		const reviews = await Review.find({ imdbID: req.params.imdbID }).populate(
			"userId",
			"username email"
		);
		res.status(200).json(reviews);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch reviews", error });
	}
});

// Add a review
router.post("/", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { imdbID, reviewText, rating } = req.body;
		const userId = req.user?.id;

		if (!imdbID || !reviewText || !userId) {
			return res.status(400).json({ message: "Missing required fields" });
		}

		const newReview = new Review({
			userId,
			imdbID,
			reviewText,
			rating,
		});

		await newReview.save();
		await newReview.populate("userId", "username email");
		res.status(201).json({ message: "Review added", data: newReview });
	} catch (error) {
		res.status(500).json({ message: "Failed to add review", error });
	}
});

export default router;
