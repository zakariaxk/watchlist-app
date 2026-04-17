import cors from "cors";
import express from "express";
import helmet from "helmet";
import path from "path";
import rateLimit from "express-rate-limit";

import authRoutes from "./routes/authRoutes";
import mediaRoutes from "./routes/mediaRoutes";
import watchlistRoutes from "./routes/watchlistRoutes";
import reviewRoutes from "./routes/commentRoutes";
import reviewCommentRoutes from "./routes/reviewCommentRoutes";
// hsp - import user routes for search and public profile lookup
import userRoutes from "./routes/userRoutes";
import feedRoutes from "./routes/feedRoutes";
import friendRoutes from "./routes/friendRoutes";
import { getAllowedOrigins } from "./config/env";

const app = express();
const isProduction = process.env.NODE_ENV === "production";
const allowedOrigins = getAllowedOrigins();

app.set("trust proxy", 1);

app.use(
	helmet({
		crossOriginResourcePolicy: false,
	}),
);

app.use(
	cors({
		origin: (origin, callback) => {
			// Native mobile apps and server-to-server calls often omit Origin.
			if (!origin) {
				callback(null, true);
				return;
			}

			if (origin && allowedOrigins.includes(origin)) {
				callback(null, true);
			} else {
				callback(new Error("Not allowed by CORS"));
			}
		},
		credentials: true,
	})
);

app.use(express.json());

const authLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: isProduction ? 200 : 1000,
	standardHeaders: true,
	legacyHeaders: false,
});

app.get("/api/health", (_req, res) => {
	res.status(200).json({ status: "ok" });
});

app.use("/api/auth", authLimiter, authRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/watchlist", watchlistRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/review-comments", reviewCommentRoutes);
// hsp - user search + public profile routes
app.use("/api/users", userRoutes);
app.use("/api/feed", feedRoutes);
app.use("/api/friends", friendRoutes);

// Serve static files from the client dist folder
app.use(express.static(path.join(__dirname, "../../client/dist")));

app.use((req, res) => {
	if (req.path.startsWith("/api")) {
		return res.status(404).json({ error: "API route not found" });
	}

	res.sendFile(path.join(__dirname, "../../client/dist/index.html"));
});

export default app;
