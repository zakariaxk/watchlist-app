import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import jwt from "jsonwebtoken";
import app from "../src/app";
import Review from "../src/models/Comment";
import ReviewComment from "../src/models/ReviewComment";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";
import { seedUser } from "./helpers/testUtils";

const authHeaderForUser = (userId: string): string => {
	const secret = process.env.JWT_SECRET || "secret";
	return `Bearer ${jwt.sign({ id: userId }, secret, { expiresIn: "7d" })}`;
};

describe("Reviews and review comments", () => {
	let restoreConsole: (() => void) | null = null;

	before(async () => {
		restoreConsole = silenceConsole();
		process.env.NODE_ENV = "test";
		process.env.JWT_SECRET = "test-secret";
		await connectTestDb();
	});

	beforeEach(async () => {
		await resetTestDb();
	});

	after(async () => {
		await disconnectTestDb();
		restoreConsole?.();
	});

	it("creates and lists reviews by imdbID", async () => {
		const { userId } = await seedUser({
			username: "reviewer",
			email: "reviewer@example.com",
			password: "Passw0rd!",
		});

		const addRes = await request(app)
			.post("/api/reviews")
			.set("Authorization", authHeaderForUser(userId))
			.send({ imdbID: "tt1375666", reviewText: "Great movie", rating: 9 });
		assert.equal(addRes.status, 201);
		assert.equal(addRes.body.data.imdbID, "tt1375666");

		const listRes = await request(app).get("/api/reviews/tt1375666");
		assert.equal(listRes.status, 200);
		assert.equal(listRes.body.length, 1);
		assert.equal(listRes.body[0].reviewText, "Great movie");
	});

	it("creates and lists comments for a review", async () => {
		const { userId } = await seedUser({
			username: "author",
			email: "author@example.com",
			password: "Passw0rd!",
		});

		const review = await Review.create({
			userId,
			imdbID: "tt1375666",
			reviewText: "Nice",
			rating: 8,
		});

		const addRes = await request(app)
			.post("/api/review-comments")
			.set("Authorization", authHeaderForUser(userId))
			.send({ reviewId: String(review._id), commentText: "Agreed" });
		assert.equal(addRes.status, 201);

		const listRes = await request(app).get(`/api/review-comments/${review._id}`);
		assert.equal(listRes.status, 200);
		assert.equal(listRes.body.length, 1);
		assert.equal(listRes.body[0].commentText, "Agreed");

		const dbCount = await ReviewComment.countDocuments({ reviewId: review._id });
		assert.equal(dbCount, 1);
	});
});
