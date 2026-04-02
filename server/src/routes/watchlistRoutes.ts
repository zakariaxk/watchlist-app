import { Router, Response } from "express";
import Watchlist from "../models/Watchlist";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// Get user's watchlist
router.get("/:userId", async (req: AuthRequest, res: Response) => {
	try {
		const watchlist = await Watchlist.find({ userId: req.params.userId });
		res.status(200).json(watchlist);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch watchlist", error });
	}
});

// Add to watchlist
router.post("/", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { imdbID, status, userRating, title, poster } = req.body;
		const userId = req.user?.id;

		if (!imdbID || !userId) {
			return res.status(400).json({ message: "imdbID and userId are required" });
		}

		const existingItem = await Watchlist.findOne({ userId, imdbID });
		if (existingItem) {
			return res.status(400).json({ message: "Item already in watchlist" });
		}

		const watchlistItem = new Watchlist({
			userId,
			imdbID,
			status: status || "plan_to_watch",
			userRating,
			title,
			poster,
		});

		await watchlistItem.save();
		res.status(201).json({ message: "Added to watchlist", data: watchlistItem });
	} catch (error) {
		res.status(500).json({ message: "Failed to add to watchlist", error });
	}
});

// Update watchlist item
router.put("/:id", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { status, userRating } = req.body;

		const watchlistItem = await Watchlist.findByIdAndUpdate(
			req.params.id,
			{ status, userRating },
			{ new: true }
		);

		if (!watchlistItem) {
			return res.status(404).json({ message: "Watchlist item not found" });
		}

		res.status(200).json({ message: "Updated", data: watchlistItem });
	} catch (error) {
		res.status(500).json({ message: "Failed to update watchlist", error });
	}
});

// Delete from watchlist
router.delete("/:id", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const watchlistItem = await Watchlist.findByIdAndDelete(req.params.id);

		if (!watchlistItem) {
			return res.status(404).json({ message: "Watchlist item not found" });
		}

		res.status(200).json({ message: "Deleted from watchlist" });
	} catch (error) {
		res.status(500).json({ message: "Failed to delete from watchlist", error });
	}
});

export default router;
