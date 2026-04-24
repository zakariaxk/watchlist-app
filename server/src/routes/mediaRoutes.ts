import { Router, Request, Response as ExpressResponse } from "express";

import Media from "../models/Media";
import { fetchOmdbJson } from "../utils/omdb";

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

		const typeParam =
			type === "movie" || type === "series"
				? `&type=${encodeURIComponent(type as string)}`
				: "";
		const pageNum = typeof page === "string" && /^\d+$/.test(page) ? parseInt(page, 10) : 1;
		const pageParam = pageNum > 1 ? `&page=${pageNum}` : "";
		const omdbResult = await fetchOmdbJson(
			`https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&s=${encodeURIComponent(title.trim())}${typeParam}${pageParam}`,
			{ notFoundMessage: "No results found" }
		);

		if (!omdbResult.ok) {
			return res.status(omdbResult.error.status).json(omdbResult.error.body);
		}

		const rawResults = omdbResult.data["Search"] as Record<string, unknown>[];
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
		return res.status(500).json({ message: "Failed to search media" });
	}
});

// GET /api/media/:imdbID
// Returns media detail. Always fetches full data from OMDb for display fields.
// Upserts imdbID + title into MongoDB for reference. Does not store extra fields.
router.get("/:imdbID", async (req: Request, res: ExpressResponse) => {
	try {
		const imdbID = req.params.imdbID as string;

		const apiKey = getOmdbApiKey();
		if (!apiKey) {
			return res.status(500).json({ message: "OMDb API key is not configured" });
		}

		const omdbResult = await fetchOmdbJson(
			`https://www.omdbapi.com/?apikey=${encodeURIComponent(apiKey)}&i=${encodeURIComponent(imdbID)}`,
			{ notFoundMessage: "Media not found" }
		);

		if (!omdbResult.ok) {
			return res.status(omdbResult.error.status).json(omdbResult.error.body);
		}

		const omdbData = omdbResult.data;
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
		return res.status(500).json({ message: "Failed to fetch media" });
	}
});

export default router;
