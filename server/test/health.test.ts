import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import app from "../src/app";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";

describe("GET /api/health", () => {
	let restoreConsole: (() => void) | null = null;

	before(async () => {
		restoreConsole = silenceConsole();
		process.env.JWT_SECRET = "test-secret";
		process.env.NODE_ENV = "test";
		await connectTestDb();
	});

	beforeEach(async () => {
		await resetTestDb();
	});

	after(async () => {
		await disconnectTestDb();
		restoreConsole?.();
	});

	it("returns ok", async () => {
		const res = await request(app).get("/api/health");
		assert.equal(res.status, 200);
		assert.deepEqual(res.body, { status: "ok" });
	});
});
