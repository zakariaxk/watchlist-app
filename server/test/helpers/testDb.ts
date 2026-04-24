import mongoose from "mongoose";
import { MongoMemoryServer } from "mongodb-memory-server";

let mongo: MongoMemoryServer | null = null;

export const connectTestDb = async (): Promise<void> => {
	if (mongo) {
		return;
	}

	mongo = await MongoMemoryServer.create();
	const uri = mongo.getUri();
	await mongoose.connect(uri);
};

export const resetTestDb = async (): Promise<void> => {
	if (!mongoose.connection.readyState) {
		return;
	}

	const db = mongoose.connection.db;
	if (db) {
		await db.dropDatabase();
	}
};

export const disconnectTestDb = async (): Promise<void> => {
	if (mongoose.connection.readyState) {
		await mongoose.disconnect();
	}
	if (mongo) {
		await mongo.stop();
		mongo = null;
	}
};

