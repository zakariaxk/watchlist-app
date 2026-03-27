import cors from "cors";
import express from "express";
import path from "path";

import authRoutes from "./routes/authRoutes";
import mediaRoutes from "./routes/mediaRoutes";
import watchlistRoutes from "./routes/watchlistRoutes";
import commentRoutes from "./routes/commentRoutes";

const app = express();

app.use(cors());
app.use(express.json());

app.get("/api/health", (_req, res) => {
	res.json({ message: "Server is running" });
});

app.use("/api/auth", authRoutes);
app.use("/api/media", mediaRoutes);
app.use("/api/watchlist", watchlistRoutes);
app.use("/api/comments", commentRoutes);

// Serve static files from the client dist folder
app.use(express.static(path.join(__dirname, "../../client/dist")));

// Fallback route for SPA routing - serve index.html for any non-API route
app.get("*", (_req, res) => {
	res.sendFile(path.join(__dirname, "../../client/dist/index.html"));
});

export default app;
