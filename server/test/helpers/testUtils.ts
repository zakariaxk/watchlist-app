import crypto from "node:crypto";
import bcryptjs from "bcryptjs";
import User from "../../src/models/User";

export const sha256Hex = (value: string): string => {
	return crypto.createHash("sha256").update(value).digest("hex");
};

export const seedUser = async (params: {
	username: string;
	email: string;
	password: string;
	isVerified?: boolean;
	profileVisibility?: "public" | "private";
	isAdmin?: boolean;
}): Promise<{ userId: string }> => {
	const passwordHash = await bcryptjs.hash(params.password, 10);
	const user = await User.create({
		username: params.username,
		email: params.email,
		passwordHash,
		isVerified: params.isVerified ?? true,
		profileVisibility: params.profileVisibility ?? "public",
		isAdmin: params.isAdmin ?? false,
	});

	return { userId: String(user._id) };
};

