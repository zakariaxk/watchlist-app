import "dotenv/config";

import app from "./app";
import connectDB from "./config/db";
import { bootstrapTestAdmin } from "./utils/bootstrapTestAdmin";

const port = process.env.PORT || 5001;

const startServer = async () => {
	await connectDB();
	await bootstrapTestAdmin();

	app.listen(port, () => {
		console.log(`Server listening on port ${port}`);
	});
};

startServer().catch((error) => {
	console.error("Server startup failed:", error);
	process.exit(1);
});
