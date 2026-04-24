import { Router, Response } from "express";
import Watchlist from "../models/Watchlist";
import Media from "../models/Media";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();
const watchlistDebug = process.env.WATCHLIST_DEBUG === "true";

type WatchlistResponseItem = {
	_id: unknown;
	userId: unknown;
	imdbID: string;
	status: string;
	userRating?: number;
	title?: string;
	poster?: string;
	dateAdded?: Date;
};

const getOmdbApiKey = (): string | null => process.env.OMDB_API_KEY || null;

const normalizeTitle = (title: unknown): string | undefined => {
	if (typeof title !== "string") {
		return undefined;
	}
	const trimmed = title.trim();
	return trimmed ? trimmed : undefined;
};

const normalizePoster = (poster: unknown): string | undefined => {
	if (typeof poster !== "string") {
		return undefined;
	}
	const trimmed = poster.trim();
	if (!trimmed || trimmed === "N/A") {
		return undefined;
	}
	return trimmed;
};

const fetchOmdbMetadataByImdbID = async (
	imdbID: string
): Promise<{ title?: string; poster?: string }> => {
	const apiKey = getOmdbApiKey();
	if (!apiKey) {
		return {};
	}

	try {
		const omdbRes = await fetch(
			`https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&i=${encodeURIComponent(imdbID)}`
		);

		if (!omdbRes.ok) {
			return {};
		}

		const omdbData = (await omdbRes.json()) as Record<string, unknown>;
		if (omdbData["Response"] === "False") {
			return {};
		}

		return {
			title: normalizeTitle(omdbData["Title"]),
			poster: normalizePoster(omdbData["Poster"]),
		};
	} catch {
		return {};
	}
};

const resolveWatchlistMetadata = async (
	imdbID: string,
	currentTitle?: string,
	currentPoster?: string
): Promise<{ title?: string; poster?: string }> => {
	let resolvedTitle = normalizeTitle(currentTitle);
	let resolvedPoster = normalizePoster(currentPoster);

	if (!resolvedTitle || !resolvedPoster) {
		const mediaDoc = (await Media.findOne({ imdbID })
			.select("title poster")
			.lean()) as { title?: string; poster?: string } | null;

		if (!resolvedTitle) {
			resolvedTitle = normalizeTitle(mediaDoc?.title);
		}
		if (!resolvedPoster) {
			resolvedPoster = normalizePoster(mediaDoc?.poster);
		}
	}

	if (!resolvedTitle || !resolvedPoster) {
		const omdbMeta = await fetchOmdbMetadataByImdbID(imdbID);
		if (!resolvedTitle) {
			resolvedTitle = omdbMeta.title;
		}
		if (!resolvedPoster) {
			resolvedPoster = omdbMeta.poster;
		}
	}

	// Keep media cache populated for future lookups when we know a valid title.
	if (resolvedTitle) {
		await Media.findOneAndUpdate(
			{ imdbID },
			{
				imdbID,
				title: resolvedTitle,
				poster: resolvedPoster ?? "",
			},
			{ upsert: true, setDefaultsOnInsert: true }
		).catch(() => undefined);
	}

	return {
		title: resolvedTitle,
		poster: resolvedPoster,
	};
};

const enrichWatchlistResponse = async (
	watchlist: WatchlistResponseItem[]
): Promise<WatchlistResponseItem[]> => {
	return Promise.all(
		watchlist.map(async (item) => {
			const fallbackTitle = normalizeTitle(item.title) || item.imdbID || "Unknown Title";
			const fallbackPoster = normalizePoster(item.poster) || "";

			if (!item.imdbID) {
				return {
					...item,
					title: fallbackTitle,
					poster: fallbackPoster,
				};
			}

			const metadata = await resolveWatchlistMetadata(item.imdbID, item.title, item.poster);

			return {
				...item,
				title: metadata.title || fallbackTitle,
				poster: metadata.poster || fallbackPoster,
			};
		})
	);
};

// Get authenticated user's watchlist
router.get("/", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const userId = req.user?.id;
		if (!userId) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		const watchlist = (await Watchlist.find({ userId }).lean()) as WatchlistResponseItem[];
		const enrichedWatchlist = await enrichWatchlistResponse(watchlist);

		if (watchlistDebug) {
			console.log("[watchlist:get:self]", {
				authUserId: userId,
				count: enrichedWatchlist.length,
			});
		}

		res.status(200).json(enrichedWatchlist);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch watchlist", error });
	}
});

// Get user's watchlist
router.get("/:userId", async (req: AuthRequest, res: Response) => {
	try {
		const watchlist = (await Watchlist.find({
			userId: req.params.userId,
		}).lean()) as WatchlistResponseItem[];
		const enrichedWatchlist = await enrichWatchlistResponse(watchlist);

		if (watchlistDebug) {
			console.log("[watchlist:get:byUserId]", {
				paramUserId: req.params.userId,
				count: enrichedWatchlist.length,
			});
		}

		res.status(200).json(enrichedWatchlist);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch watchlist", error });
	}
});

// Add to watchlist
router.post("/", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { imdbID, status, userRating, title, poster, isFavorite } = req.body;
		const userId = req.user?.id;

		if (watchlistDebug) {
			console.log("[watchlist:post]", {
				body: req.body,
				authUser: req.user,
			});
		}

		if (!imdbID || !userId) {
			return res.status(400).json({ message: "imdbID and userId are required" });
		}

		const existingItem = await Watchlist.findOne({ userId, imdbID });

		if (watchlistDebug) {
			console.log("[watchlist:post:duplicate-check]", {
				query: { userId, imdbID },
				found: Boolean(existingItem),
			});
		}

		if (existingItem) {
			return res.status(400).json({ message: "Item already in watchlist" });
		}

		const incomingTitle = normalizeTitle(title);
		const incomingPoster = normalizePoster(poster);
		const metadata = await resolveWatchlistMetadata(imdbID, incomingTitle, incomingPoster);

		const watchlistItem = new Watchlist({
			userId,
			imdbID,
			status: status || "plan_to_watch",
			userRating,
			title: incomingTitle || metadata.title,
			poster: incomingPoster || metadata.poster || "",
			isFavorite: typeof isFavorite === "boolean" ? isFavorite : undefined,
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
		const { status, userRating, isFavorite } = req.body;
		const userId = req.user?.id;

		if (!userId) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		const update: Record<string, unknown> = {};
		if (typeof status === "string") {
			update.status = status;
		}
		if (typeof userRating === "number") {
			update.userRating = userRating;
		}
		if (typeof isFavorite === "boolean") {
			update.isFavorite = isFavorite;
		}

		if (Object.keys(update).length == 0) {
			return res.status(400).json({ message: "No updates provided" });
		}

		const watchlistItem = await Watchlist.findOneAndUpdate(
			{ _id: req.params.id, userId },
			update,
			{ new: true }
		);

		if (!watchlistItem) {
			return res.status(404).json({ message: "Watchlist item not found or not owned by user" });
		}

		res.status(200).json({ message: "Updated", data: watchlistItem });
	} catch (error) {
		res.status(500).json({ message: "Failed to update watchlist", error });
	}
});

// Delete from watchlist
router.delete("/:id", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const userId = req.user?.id;

		if (!userId) {
			return res.status(401).json({ message: "Unauthorized" });
		}

		const watchlistItem = await Watchlist.findOneAndDelete({
			_id: req.params.id,
			userId,
		});

		if (!watchlistItem) {
			return res.status(404).json({ message: "Watchlist item not found or not owned by user" });
		}

		res.status(200).json({ message: "Deleted from watchlist", id: req.params.id });
	} catch (error) {
		res.status(500).json({ message: "Failed to delete from watchlist", error });
	}
});

export default router;
