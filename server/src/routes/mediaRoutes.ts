import { Router, Request, Response as ExpressResponse } from "express";
import Media from "../models/Media";

const router = Router();

const getOmdbApiKey = (): string | null => process.env.OMDB_API_KEY || null;

// GET /api/media/search?title=...&type=movie|series&page=1
// Calls OMDb search endpoint and returns results. Does not persist to DB.
router.get("/search", async (req: Request, res: ExpressResponse) => {
	try {
		const { title, type, page } = req.query;

		if (!title || typeof title !== "string" || title.trim() === "") {
			return res.status(400).json({ message: "title query parameter is required" });
		}

		const apiKey = getOmdbApiKey();
		if (!apiKey) {
			return res.status(500).json({ message: "OMDb API key is not configured" });
		}

		let omdbData: Record<string, unknown>;
		try {
			// Build URL — add &type= only when explicitly specified
			const typeParam =
				type === "movie" || type === "series"
					? `&type=${encodeURIComponent(type as string)}`
					: "";
			const pageNum = typeof page === "string" && /^\d+$/.test(page) ? parseInt(page, 10) : 1;
			const pageParam = pageNum > 1 ? `&page=${pageNum}` : "";
			const omdbRes = await fetch(
				`https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&s=${encodeURIComponent(title.trim())}${typeParam}${pageParam}`
			);
			if (!omdbRes.ok) {
				return res.status(502).json({ message: "OMDb API request failed" });
			}
			omdbData = (await omdbRes.json()) as Record<string, unknown>;
		} catch {
			return res.status(502).json({ message: "Failed to reach OMDb API" });
		}

		if (omdbData["Response"] === "False") {
			return res
				.status(404)
				.json({ message: (omdbData["Error"] as string) || "No results found" });
		}

		const rawResults = omdbData["Search"] as Record<string, unknown>[];
		const results = rawResults.map((item) => ({
			imdbID: item["imdbID"],
			title: item["Title"],
			year: item["Year"],
			type: item["Type"],
			poster: item["Poster"],
		}));

		return res.status(200).json({ results });
	} catch (error) {
		console.error("Media search error:", error);
		res.status(500).json({ message: "Failed to search media" });
	}
});

// GET /api/media/:imdbID
// Returns media detail. Always fetches full data from OMDb for display fields.
// Upserts imdbID + title into MongoDB for reference. Does not store extra fields.
router.get("/:imdbID", async (req: Request, res: ExpressResponse) => {
	try {
		// Cast to string — req.params values are always strings in Express route handlers
		const imdbID = req.params.imdbID as string;

		const apiKey = getOmdbApiKey();
		if (!apiKey) {
			return res.status(500).json({ message: "OMDb API key is not configured" });
		}

		// Fetch full detail from OMDb
		let omdbData: Record<string, unknown>;
		try {
			const omdbRes = await fetch(
				`https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&i=${encodeURIComponent(imdbID)}`
			);
			if (!omdbRes.ok) {
				return res.status(502).json({ message: "OMDb API request failed" });
			}
			omdbData = (await omdbRes.json()) as Record<string, unknown>;
		} catch {
			return res.status(502).json({ message: "Failed to reach OMDb API" });
		}

		if (omdbData["Response"] === "False") {
			return res
				.status(404)
				.json({ message: (omdbData["Error"] as string) || "Media not found" });
		}

				// Upsert into DB (store imdbID + title + poster)
		const posterValue =
			typeof omdbData["Poster"] === "string" && omdbData["Poster"] !== "N/A"
				? omdbData["Poster"]
				: "";

		const dbMedia = await Media.findOneAndUpdate(
			{ imdbID },
			{
				imdbID: omdbData["imdbID"],
				title: omdbData["Title"],
				poster: posterValue,
			},
			{
				new: true,
				upsert: true,
				setDefaultsOnInsert: true,
			}
		);

		// Return DB doc merged with OMDb display fields
		return res.status(200).json({
			_id: dbMedia._id,
			imdbID: dbMedia.imdbID,
			title: dbMedia.title,
			createdAt: dbMedia.createdAt,
			year: omdbData["Year"],
			type: omdbData["Type"],
			genres:
				typeof omdbData["Genre"] === "string"
					? (omdbData["Genre"] as string).split(", ")
					: [],
			poster:
				typeof omdbData["Poster"] === "string" && omdbData["Poster"] !== "N/A"
					? omdbData["Poster"]
					: "",
		});
	} catch (error) {
		console.error("Media fetch error:", error);
		res.status(500).json({ message: "Failed to fetch media" });
	}
});

export default router;
