import { after, before, beforeEach, describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import app from "../src/app";
import Media from "../src/models/Media";
import { connectTestDb, disconnectTestDb, resetTestDb } from "./helpers/testDb";
import { silenceConsole } from "./helpers/silenceConsole";

type MockFetch = typeof fetch;

describe("Media routes", () => {
	let originalFetch: MockFetch;
	let restoreConsole: (() => void) | null = null;

	before(async () => {
		restoreConsole = silenceConsole();
		process.env.NODE_ENV = "test";
		process.env.JWT_SECRET = "test-secret";
		process.env.OMDB_API_KEY = "fake-key";
		await connectTestDb();

		originalFetch = globalThis.fetch;
		globalThis.fetch = (async (url: any) => {
			const urlString = String(url);

			if (urlString.includes("&s=")) {
				if (urlString.includes("&s=limit-hit")) {
					return {
						ok: true,
						json: async () => ({
							Response: "False",
							Error: "Request limit reached!",
						}),
					} as any;
				}

				return {
					ok: true,
					json: async () => ({
						Response: "True",
						Search: [
							{
								imdbID: "tt1375666",
								Title: "Inception",
								Year: "2010",
								Type: "movie",
								Poster: "N/A",
							},
						],
					}),
				} as any;
			}

			if (urlString.includes("&i=tt1375666")) {
				return {
					ok: true,
					json: async () => ({
						Response: "True",
						imdbID: "tt1375666",
						Title: "Inception",
						Year: "2010",
						Type: "movie",
						Genre: "Action, Sci-Fi",
						Poster: "https://example.com/poster.jpg",
					}),
				} as any;
			}

			if (urlString.includes("&i=ttlimit0001")) {
				return {
					ok: true,
					json: async () => ({
						Response: "False",
						Error: "Request limit reached!",
					}),
				} as any;
			}

			return { ok: false, json: async () => ({}) } as any;
		}) as any;
	});

	beforeEach(async () => {
		await resetTestDb();
	});

	after(async () => {
		globalThis.fetch = originalFetch;
		await disconnectTestDb();
		restoreConsole?.();
	});

	it("requires title query for search", async () => {
		const res = await request(app).get("/api/media/search");
		assert.equal(res.status, 400);
	});

	it("searches via OMDb and returns results", async () => {
		const res = await request(app).get("/api/media/search").query({ title: "inception" });
		assert.equal(res.status, 200);
		assert.equal(res.body.results.length, 1);
		assert.equal(res.body.results[0].imdbID, "tt1375666");
	});

	it("returns a controlled 429 when the OMDb daily limit is reached during search", async () => {
		const res = await request(app).get("/api/media/search").query({ title: "limit-hit" });
		assert.equal(res.status, 429);
		assert.deepEqual(res.body, {
			code: "OMDB_RATE_LIMIT_REACHED",
			message: "OMDb daily request limit reached. Please try again later.",
		});
	});

	it("fetches details and upserts minimal Media document", async () => {
		const res = await request(app).get("/api/media/tt1375666");
		assert.equal(res.status, 200);
		assert.equal(res.body.imdbID, "tt1375666");
		assert.equal(res.body.title, "Inception");
		assert.deepEqual(res.body.genres, ["Action", "Sci-Fi"]);

		const dbMedia = await Media.findOne({ imdbID: "tt1375666" }).lean();
		assert.ok(dbMedia);
		assert.equal(dbMedia?.title, "Inception");
		assert.equal(dbMedia?.poster, "https://example.com/poster.jpg");
	});

	it("returns a controlled 429 when the OMDb daily limit is reached for details", async () => {
		const res = await request(app).get("/api/media/ttlimit0001");
		assert.equal(res.status, 429);
		assert.deepEqual(res.body, {
			code: "OMDB_RATE_LIMIT_REACHED",
			message: "OMDb daily request limit reached. Please try again later.",
		});
	});
});
