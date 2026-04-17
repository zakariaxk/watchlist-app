import bcryptjs from "bcryptjs";

import User from "../models/User";

const DEFAULT_TEST_ADMIN_USERNAME = "admin";
const DEFAULT_TEST_ADMIN_EMAIL = "admin@watchit.local";
const getEnvFlag = (name: string): boolean => {
	return String(process.env[name] || "").toLowerCase() === "true";
};

const shouldBootstrapTestAdmin = (): boolean => {
	if (process.env.NODE_ENV === "production") {
		return false;
	}
	return getEnvFlag("ENABLE_TEST_ADMIN");
};

export const isTestAdminBypassEnabled = (): boolean => {
	if (process.env.NODE_ENV === "production") {
		return false;
	}
	return getEnvFlag("ENABLE_TEST_ADMIN");
};

export const bootstrapTestAdmin = async (): Promise<void> => {
	if (!shouldBootstrapTestAdmin()) {
		console.log("[test-admin] Skipped (disabled or production environment)");
		return;
	}

	const username = (process.env.TEST_ADMIN_USERNAME || DEFAULT_TEST_ADMIN_USERNAME).trim();
	const email = (process.env.TEST_ADMIN_EMAIL || DEFAULT_TEST_ADMIN_EMAIL).trim().toLowerCase();
	const password = process.env.TEST_ADMIN_PASSWORD || "";

	if (!username || !email || !password) {
		console.warn("[test-admin] Missing TEST_ADMIN_PASSWORD or credentials configuration, skipping bootstrap");
		return;
	}

	const passwordHash = await bcryptjs.hash(password, 10);

	const adminUser = await User.findOneAndUpdate(
		{ $or: [{ email }, { username }] },
		{
			username,
			email,
			passwordHash,
			isAdmin: true,
			isVerified: true,
			verificationToken: null,
			VerificationTokenExpires: null,
		},
		{ upsert: true, new: true, setDefaultsOnInsert: true },
	);

	console.log(`[test-admin] Ready: ${adminUser.username} (${adminUser.email})`);
};
