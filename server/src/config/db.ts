import mongoose from "mongoose";

const connectDB = async () => {
	try {
		const mongoUri = process.env.MONGO_URI;
		if (!mongoUri) {
			throw new Error("MONGO_URI is missing. Set it in server/.env before starting the server.");
		}
		await mongoose.connect(mongoUri);
		console.log("MongoDB connected successfully");
	} catch (error) {
		console.error("MongoDB connection failed:", error);
		process.exit(1);
	}
};

export default connectDB;
