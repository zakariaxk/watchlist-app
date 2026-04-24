import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import jwt from "jsonwebtoken";
import app from "../src/app";
import Friend from "../src/models/Friend";
import Watchlist from "../src/models/Watchlist";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";
import { seedUser } from "./helpers/testUtils";

const authHeaderForUser = (userId: string): string => {
	const secret = process.env.JWT_SECRET || "secret";
	return `Bearer ${jwt.sign({ id: userId }, secret, { expiresIn: "7d" })}`;
};

describe("Users, friends, and feed routes", () => {
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

	it("searches users by username (min length enforced)", async () => {
		await seedUser({ username: "johnny", email: "j@example.com", password: "Passw0rd!" });
		await seedUser({ username: "jane", email: "ja@example.com", password: "Passw0rd!" });

		const badRes = await request(app).get("/api/users/search").query({ query: "j" });
		assert.equal(badRes.status, 400);

		const res = await request(app).get("/api/users/search").query({ query: "jan" });
		assert.equal(res.status, 200);
		assert.equal(res.body.users.length, 1);
		assert.equal(res.body.users[0].username, "jane");
	});

	it("returns limited view for private profiles", async () => {
		const { userId } = await seedUser({
			username: "private_user",
			email: "p@example.com",
			password: "Passw0rd!",
			profileVisibility: "private",
		});

		const res = await request(app).get(`/api/users/${userId}`);
		assert.equal(res.status, 200);
		assert.equal(res.body.profileVisibility, "private");
		assert.ok(!("createdAt" in res.body));
	});

	it("follows and unfollows users", async () => {
		const { userId: userIdA } = await seedUser({
			username: "a",
			email: "a@example.com",
			password: "Passw0rd!",
		});
		const { userId: userIdB } = await seedUser({
			username: "b",
			email: "b@example.com",
			password: "Passw0rd!",
		});

		const followRes = await request(app)
			.post(`/api/friends/${userIdB}`)
			.set("Authorization", authHeaderForUser(userIdA));
		assert.equal(followRes.status, 201);

		const checkRes = await request(app)
			.get(`/api/friends/check/${userIdB}`)
			.set("Authorization", authHeaderForUser(userIdA));
		assert.equal(checkRes.status, 200);
		assert.equal(checkRes.body.following, true);

		const listRes = await request(app)
			.get("/api/friends")
			.set("Authorization", authHeaderForUser(userIdA));
		assert.equal(listRes.status, 200);
		assert.equal(listRes.body.length, 1);
		assert.equal(listRes.body[0].username, "b");

		const unfollowRes = await request(app)
			.delete(`/api/friends/${userIdB}`)
			.set("Authorization", authHeaderForUser(userIdA));
		assert.equal(unfollowRes.status, 200);

		const dbCount = await Friend.countDocuments({ userId: userIdA, friendId: userIdB });
		assert.equal(dbCount, 0);
	});

	it("feed returns public activity only", async () => {
		const { userId: publicUserId } = await seedUser({
			username: "pub",
			email: "pub@example.com",
			password: "Passw0rd!",
			profileVisibility: "public",
		});
		const { userId: privateUserId } = await seedUser({
			username: "priv",
			email: "priv@example.com",
			password: "Passw0rd!",
			profileVisibility: "private",
		});

		await Watchlist.create({
			userId: publicUserId,
			imdbID: "tt1",
			status: "watching",
			title: "Public Title",
			poster: "",
		});
		await Watchlist.create({
			userId: privateUserId,
			imdbID: "tt2",
			status: "watching",
			title: "Private Title",
			poster: "",
		});

		const res = await request(app).get("/api/feed");
		assert.equal(res.status, 200);
		assert.equal(res.body.length, 1);
		assert.equal(res.body[0].username, "pub");
		assert.equal(res.body[0].title, "Public Title");
	});

	it("friends feed returns activity from followed users", async () => {
		const { userId: viewerId } = await seedUser({
			username: "viewer",
			email: "viewer@example.com",
			password: "Passw0rd!",
		});
		const { userId: friendId } = await seedUser({
			username: "friend",
			email: "friend@example.com",
			password: "Passw0rd!",
		});
		const { userId: strangerId } = await seedUser({
			username: "stranger",
			email: "stranger@example.com",
			password: "Passw0rd!",
		});

		await Friend.create({ userId: viewerId, friendId });

		await Watchlist.create({
			userId: friendId,
			imdbID: "tt3",
			status: "completed",
			title: "Friend Title",
			poster: "",
		});
		await Watchlist.create({
			userId: strangerId,
			imdbID: "tt4",
			status: "completed",
			title: "Stranger Title",
			poster: "",
		});

		const res = await request(app)
			.get("/api/feed/friends")
			.set("Authorization", authHeaderForUser(viewerId));
		assert.equal(res.status, 200);
		assert.equal(res.body.length, 1);
		assert.equal(res.body[0].username, "friend");
		assert.equal(res.body[0].title, "Friend Title");
	});
});
