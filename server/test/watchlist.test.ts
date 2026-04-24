import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import jwt from "jsonwebtoken";
import app from "../src/app";
import Watchlist from "../src/models/Watchlist";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";
import { seedUser } from "./helpers/testUtils";

const authHeaderForUser = (userId: string): string => {
	const secret = process.env.JWT_SECRET || "secret";
	return `Bearer ${jwt.sign({ id: userId }, secret, { expiresIn: "7d" })}`;
};

describe("Watchlist routes", () => {
	let restoreConsole: (() => void) | null = null;

	before(async () => {
		restoreConsole = silenceConsole();
		process.env.NODE_ENV = "test";
		process.env.JWT_SECRET = "test-secret";
		process.env.OMDB_API_KEY = "";
		await connectTestDb();
	});

	beforeEach(async () => {
		await resetTestDb();
	});

	after(async () => {
		await disconnectTestDb();
		restoreConsole?.();
	});

	it("adds, updates, lists, and deletes watchlist items", async () => {
		const { userId } = await seedUser({
			username: "alice",
			email: "alice@example.com",
			password: "Passw0rd!",
		});

		const addRes = await request(app)
			.post("/api/watchlist")
			.set("Authorization", authHeaderForUser(userId))
			.send({
				imdbID: "tt1375666",
				status: "plan_to_watch",
				userRating: 8.5,
				title: "Inception",
				poster: "https://example.com/inception.jpg",
				isFavorite: true,
			});

		assert.equal(addRes.status, 201);
		const itemId = addRes.body.data._id as string;
		assert.ok(itemId);

		const listRes = await request(app)
			.get("/api/watchlist")
			.set("Authorization", authHeaderForUser(userId));
		assert.equal(listRes.status, 200);
		assert.equal(listRes.body.length, 1);
		assert.equal(listRes.body[0].title, "Inception");

		const updateRes = await request(app)
			.put(`/api/watchlist/${itemId}`)
			.set("Authorization", authHeaderForUser(userId))
			.send({ status: "completed", userRating: 9 });
		assert.equal(updateRes.status, 200);
		assert.equal(updateRes.body.data.status, "completed");

		const deleteRes = await request(app)
			.delete(`/api/watchlist/${itemId}`)
			.set("Authorization", authHeaderForUser(userId));
		assert.equal(deleteRes.status, 200);

		const db = await Watchlist.findById(itemId).lean();
		assert.equal(db, null);
	});

	it("prevents updating items not owned by user", async () => {
		const { userId: ownerId } = await seedUser({
			username: "owner",
			email: "owner@example.com",
			password: "Passw0rd!",
		});
		const { userId: attackerId } = await seedUser({
			username: "attacker",
			email: "attacker@example.com",
			password: "Passw0rd!",
		});

		const created = await Watchlist.create({
			userId: ownerId,
			imdbID: "tt0000001",
			status: "plan_to_watch",
			title: "Owned Title",
			poster: "",
		});

		const res = await request(app)
			.put(`/api/watchlist/${created._id}`)
			.set("Authorization", authHeaderForUser(attackerId))
			.send({ status: "completed" });

		assert.equal(res.status, 404);
	});
});
