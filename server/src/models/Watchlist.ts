import mongoose from "mongoose";

const watchlistSchema = new mongoose.Schema({
	userId: {
		type: mongoose.Schema.Types.ObjectId,
		ref: "User",
		required: true,
	},
	imdbID: {
		type: String,
		required: true,
	},
	status: {
		type: String,
		enum: ["plan_to_watch", "watching", "completed"],
		default: "plan_to_watch",
	},
	userRating: {
		type: Number,
		min: 1,
		max: 10,
	},
	title: {
		type: String,
	},
	poster: {
		type: String,
	},
	dateAdded: {
		type: Date,
		default: Date.now,
	},
});

export default mongoose.model("Watchlist", watchlistSchema, "watchlist");
