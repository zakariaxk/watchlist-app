import cors from "cors";
import express from "express";
import path from "path";

import authRoutes from "./routes/authRoutes";
import mediaRoutes from "./routes/mediaRoutes";
import watchlistRoutes from "./routes/watchlistRoutes";
import reviewRoutes from "./routes/commentRoutes";
import reviewCommentRoutes from "./routes/reviewCommentRoutes";
// hsp - import user routes for search and public profile lookup
import userRoutes from "./routes/userRoutes";
import feedRoutes from "./routes/feedRoutes";
import friendRoutes from "./routes/friendRoutes";

const app = express();

// Enhanced CORS configuration
const allowedOrigins = [
	"http://localhost:5173",
	"http://localhost:5001",
	"http://192.241.131.53",
	"http://192.241.131.53:5001",
];

app.use(
	cors({
		origin: (origin, callback) => {
			if (!origin || allowedOrigins.includes(origin)) {
				callback(null, true);
			} else {
				callback(new Error("Not allowed by CORS"));
			}
		},
		credentials: true,
	})
);

app.use(express.json());


app.use("/api/auth", authRoutes);
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
