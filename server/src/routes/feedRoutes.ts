import { Router, Response } from "express";
import Watchlist from "../models/Watchlist";
import Friend from "../models/Friend";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

const getOmdbApiKey = (): string | null => process.env.OMDB_API_KEY || null;

// Fetch title+poster from OMDb for a single imdbID
async function enrichFromOmdb(imdbID: string, apiKey: string): Promise<{ title: string; poster: string | null }> {
  try {
    const res = await fetch(
      `https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&i=${encodeURIComponent(imdbID)}&plot=short`
    );
    if (!res.ok) return { title: imdbID, poster: null };
    const data = (await res.json()) as Record<string, unknown>;
    if (data["Response"] === "False") return { title: imdbID, poster: null };
    const poster = String(data["Poster"] || "");
    return {
      title: String(data["Title"] || imdbID),
      poster: poster && poster !== "N/A" ? poster : null,
    };
  } catch {
    return { title: imdbID, poster: null };
  }
}

// GET /api/feed/friends
// Returns the 20 most recent watchlist additions from users the current user follows.
router.get("/friends", authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const friendLinks = await Friend.find({ userId }).select("friendId").lean();
    const friendIds = friendLinks.map((link: any) => link.friendId);

    if (friendIds.length === 0) {
      return res.json([]);
    }

    const items = await Watchlist.find({ userId: { $in: friendIds } })
      .populate({ path: "userId", select: "username" })
      .sort({ dateAdded: -1 })
      .limit(80);

    const apiKey = getOmdbApiKey();

    const feed = await Promise.all(
      (items as any[]).slice(0, 20).map(async (item) => {
        let title: string = item.title || "";
        let poster: string | null = item.poster || null;

        if (!title && apiKey) {
          const enriched = await enrichFromOmdb(item.imdbID, apiKey);
          title = enriched.title;
          poster = poster || enriched.poster;
        }

        return {
          _id: item._id,
          username: item.userId?.username || "Unknown",
          imdbID: item.imdbID,
          title: title || item.imdbID,
          poster,
          status: item.status,
          userRating: item.userRating,
          dateAdded: item.dateAdded,
        };
      })
    );

    return res.json(feed);
  } catch (error) {
    return res.status(500).json({ message: "Failed to fetch friends feed", error });
  }
});

// GET /api/feed
// Returns the 20 most recent watchlist additions from users with public profiles.
router.get("/", async (_req, res: Response) => {
  try {
    const items = await Watchlist.find()
      .populate({ path: "userId", select: "username profileVisibility" })
      .sort({ dateAdded: -1 })
      .limit(80);

    const publicItems = (items as any[])
      .filter((item) => item.userId && item.userId.profileVisibility === "public")
      .slice(0, 20);

    const apiKey = getOmdbApiKey();

    // Enrich items that are missing title/poster
    const feed = await Promise.all(
      publicItems.map(async (item) => {
        let title: string = item.title || "";
        let poster: string | null = item.poster || null;

        if (!title && apiKey) {
          const enriched = await enrichFromOmdb(item.imdbID, apiKey);
          title = enriched.title;
          poster = poster || enriched.poster;
        }

        return {
          _id: item._id,
          username: item.userId.username,
          imdbID: item.imdbID,
          title: title || item.imdbID,
          poster,
          status: item.status,
          userRating: item.userRating,
          dateAdded: item.dateAdded,
        };
      })
    );

    res.json(feed);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch feed", error });
  }
});

export default router;

