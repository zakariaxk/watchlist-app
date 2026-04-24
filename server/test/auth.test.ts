import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import jwt from "jsonwebtoken";
import bcryptjs from "bcryptjs";
import app from "../src/app";
import User from "../src/models/User";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";
import { seedUser, sha256Hex } from "./helpers/testUtils";

const authHeaderForUser = (userId: string): string => {
	const secret = process.env.JWT_SECRET || "secret";
	return `Bearer ${jwt.sign({ id: userId }, secret, { expiresIn: "7d" })}`;
};

describe("Auth routes", () => {
	let restoreConsole: (() => void) | null = null;

	before(async () => {
		restoreConsole = silenceConsole();
		process.env.NODE_ENV = "test";
		process.env.JWT_SECRET = "test-secret";
		process.env.FRONTEND_URL = "http://localhost:5173";
		await connectTestDb();
	});

	beforeEach(async () => {
		await resetTestDb();
	});

	after(async () => {
		await disconnectTestDb();
		restoreConsole?.();
	});

	it("registers a user (unverified by default)", async () => {
		const res = await request(app).post("/api/auth/register").send({
			username: "alice",
			email: "alice@example.com",
			password: "AnyPassword1!",
		});

		assert.equal(res.status, 201);
		assert.equal(res.body.user.username, "alice");
		assert.equal(res.body.user.email, "alice@example.com");
		assert.ok(typeof res.body.token === "string");

		const dbUser = await User.findOne({ email: "alice@example.com" }).lean();
		assert.ok(dbUser);
		assert.equal(dbUser?.isVerified, false);
		assert.ok(dbUser?.verificationToken);
	});

	it("blocks login for unverified users", async () => {
		await seedUser({
			username: "bob",
			email: "bob@example.com",
			password: "Passw0rd!",
			isVerified: false,
		});

		const res = await request(app).post("/api/auth/login").send({
			username: "bob",
			password: "Passw0rd!",
		});

		assert.equal(res.status, 403);
	});

	it("verifies email and allows login", async () => {
		const { userId } = await seedUser({
			username: "carol",
			email: "carol@example.com",
			password: "Passw0rd!",
			isVerified: false,
		});

		const rawToken = "verify-token-123";
		await User.findByIdAndUpdate(userId, {
			verificationToken: sha256Hex(rawToken),
			VerificationTokenExpires: new Date(Date.now() + 60_000),
		});

		const verifyRes = await request(app).get("/api/auth/verify-email").query({ token: rawToken });
		assert.equal(verifyRes.status, 200);

		const loginRes = await request(app).post("/api/auth/login").send({
			username: "carol",
			password: "Passw0rd!",
		});
		assert.equal(loginRes.status, 200);
		assert.ok(typeof loginRes.body.token === "string");
	});

	it("returns current profile for authenticated user", async () => {
		const { userId } = await seedUser({
			username: "dana",
			email: "dana@example.com",
			password: "Passw0rd!",
		});

		const res = await request(app)
			.get("/api/auth/profile")
			.set("Authorization", authHeaderForUser(userId));

		assert.equal(res.status, 200);
		assert.equal(res.body.username, "dana");
		assert.equal(res.body.email, "dana@example.com");
		assert.ok(!("passwordHash" in res.body));
	});

	it("updates profile visibility", async () => {
		const { userId } = await seedUser({
			username: "erin",
			email: "erin@example.com",
			password: "Passw0rd!",
		});

		const res = await request(app)
			.patch("/api/auth/profile")
			.set("Authorization", authHeaderForUser(userId))
			.send({ profileVisibility: "private" });

		assert.equal(res.status, 200);
		assert.equal(res.body.user.profileVisibility, "private");

		const dbUser = await User.findById(userId).lean();
		assert.equal(dbUser?.profileVisibility, "private");
	});

	it("updates genre preferences", async () => {
		const { userId } = await seedUser({
			username: "frank",
			email: "frank@example.com",
			password: "Passw0rd!",
		});

		const res = await request(app)
			.patch("/api/auth/profile/preferences")
			.set("Authorization", authHeaderForUser(userId))
			.send({ genres: ["Action", "Drama", "Action", "  "] });

		assert.equal(res.status, 200);
		assert.deepEqual(res.body.user.preferredGenres, ["Action", "Drama"]);
	});

	it("sets reset token on forgot-password (generic response)", async () => {
		const { userId } = await seedUser({
			username: "gina",
			email: "gina@example.com",
			password: "Passw0rd!",
		});

		const res = await request(app).post("/api/auth/forgot-password").send({ email: "gina@example.com" });
		assert.equal(res.status, 200);
		assert.ok(typeof res.body.message === "string");

		const dbUser = await User.findById(userId).lean();
		assert.ok(dbUser?.resetPasswordToken);
		assert.ok(dbUser?.resetPasswordExpires);
	});

	it("resets password with a valid token", async () => {
		const { userId } = await seedUser({
			username: "henry",
			email: "henry@example.com",
			password: "OldPass1!",
		});

		const rawToken = "reset-token-abc";
		await User.findByIdAndUpdate(userId, {
			resetPasswordToken: sha256Hex(rawToken),
			resetPasswordExpires: new Date(Date.now() + 60_000),
		});

		const res = await request(app).post("/api/auth/reset-password").send({
			token: rawToken,
			password: "NewStrong1!",
		});

		assert.equal(res.status, 200);

		const updated = await User.findById(userId);
		assert.ok(updated);
		assert.equal(updated?.resetPasswordToken, null);
		assert.equal(updated?.resetPasswordExpires, null);
		assert.ok(await bcryptjs.compare("NewStrong1!", updated!.passwordHash));
	});
});
