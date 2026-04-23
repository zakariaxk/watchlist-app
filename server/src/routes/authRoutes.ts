import { Router, Request, Response } from "express";
import bcryptjs from "bcryptjs";
import User from "../models/User";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import { authenticate, AuthRequest } from "../middleware/auth";
import { sendPasswordResetEmail, sendVerificationEmail } from "../utils/email";
import { isTestAdminBypassEnabled } from "../utils/bootstrapTestAdmin";
import { getJwtSecret } from "../config/env";

const router = Router();
const RESET_TOKEN_TTL_MS = 60 * 60 * 1000;
const VERIFICATION_TOKEN_TTL_MS = 24 * 60 * 60 * 1000;
const GENERIC_FORGOT_PASSWORD_MESSAGE =
	"If an account exists for that email, a password reset link has been sent.";
const GENERIC_RESEND_VERIFICATION_MESSAGE =
	"If an unverified account exists for that email, a verification link has been sent.";

const hashToken = (token: string): string => {
	return crypto.createHash("sha256").update(token).digest("hex");
};

const escapeRegExp = (value: string): string => {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
};

const isConfiguredTestAdminIdentity = (user: { username?: string; email?: string }): boolean => {
	const configuredUsername = (process.env.TEST_ADMIN_USERNAME || "admin").trim().toLowerCase();
	const configuredEmail = (process.env.TEST_ADMIN_EMAIL || "admin@watchit.local").trim().toLowerCase();
	const userName = String(user.username || "").trim().toLowerCase();
	const userEmail = String(user.email || "").trim().toLowerCase();

	return userName === configuredUsername && userEmail === configuredEmail;
};

const createEmailVerificationToken = () => {
	const rawToken = crypto.randomBytes(32).toString("hex");
	return {
		rawToken,
		tokenHash: hashToken(rawToken),
		expiresAt: new Date(Date.now() + VERIFICATION_TOKEN_TTL_MS),
	};
};

const isStrongPassword = (password: string): boolean => {
	return (
		password.length >= 8 &&
		/[A-Z]/.test(password) &&
		/[a-z]/.test(password) &&
		/\d/.test(password) &&
		/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]/.test(password)
	);
};

// Register
router.post("/register", async (req: Request, res: Response) => {
	try {
		const { username, password, profileVisibility } = req.body;
		const emailInput = typeof req.body?.email === "string" ? req.body.email : "";
		const email = emailInput.trim().toLowerCase();

		if (!username || !email || !password) {
			return res.status(400).json({ message: "Username, email, and password are required" });
		}

		const existingUser = await User.findOne({ $or: [{ email }, { username }] });
		if (existingUser) {
			const existingEmail = String(existingUser.email || "").trim().toLowerCase();

			if (!existingUser.isVerified && existingEmail === email) {
				const verificationToken = createEmailVerificationToken();
				existingUser.verificationToken = verificationToken.tokenHash;
				existingUser.VerificationTokenExpires = verificationToken.expiresAt;
				await existingUser.save();

				const frontendUrl = (process.env.FRONTEND_URL || "http://localhost:5173").replace(/\/$/, "");
				const verificationLink = `${frontendUrl}/verify-email?token=${encodeURIComponent(verificationToken.rawToken)}`;

				void sendVerificationEmail(existingUser.email, verificationLink)
					.then((emailResult) => {
						if (!emailResult.delivered) {
							console.warn(`[register] Verification email was not delivered for ${existingUser.email}`);
						}
					})
					.catch((sendError) => {
						console.error(`[register] Verification email dispatch error for ${existingUser.email}:`, sendError);
					});

				return res.status(200).json({
					message:
						"Account already exists but is not verified. A new verification email has been sent.",
				});
			}

			return res.status(400).json({ message: "User already exists" });
		}

		const passwordHash = await bcryptjs.hash(password, 10);
		const verificationToken = createEmailVerificationToken();

		const newUser = new User({
			username,
			email,
			passwordHash,
			profileVisibility: profileVisibility || "public",
			verificationToken: verificationToken.tokenHash,
			VerificationTokenExpires: verificationToken.expiresAt,
			isVerified: false,
		});
		await newUser.save();

		const frontendUrl = (process.env.FRONTEND_URL || "http://localhost:5173").replace(/\/$/, "");
		const verificationLink = `${frontendUrl}/verify-email?token=${encodeURIComponent(verificationToken.rawToken)}`;

		void sendVerificationEmail(newUser.email, verificationLink)
			.then((emailResult) => {
				if (!emailResult.delivered) {
					console.warn(`[register] Verification email was not delivered for ${newUser.email}`);
				}
			})
			.catch((sendError) => {
				console.error(`[register] Verification email dispatch error for ${newUser.email}:`, sendError);
			});

		const token = jwt.sign({ id: newUser._id }, getJwtSecret(), {
			expiresIn: "7d",
		});

		res.status(201).json({
			message:
				"User registered successfully. Please check your email to verify your account. If it does not arrive, use resend verification.",
			user: {
				_id: newUser._id,
				username: newUser.username,
				email: newUser.email,
				preferredGenres: newUser.preferredGenres,
			},
			token,
		});
	} catch (error) {
		console.error("Registration error:", error);
		res.status(500).json({ message: "Registration failed. Please try again." });
	}
});

// hsp - Login
// Accepts username + password (mockup shows username field, not email).
// Never expose passwordHash in the response.
router.post("/login", async (req: Request, res: Response) => {
	try {
		const usernameInput = typeof req.body?.username === "string" ? req.body.username : "";
		const password = typeof req.body?.password === "string" ? req.body.password : "";
		const username = usernameInput.trim();

		if (!username || !password) {
			return res.status(400).json({ message: "Username and password are required" });
		}

		// Look up by username (case-insensitive match)
		const escapedUsername = escapeRegExp(username);
		const user = await User.findOne({ username: { $regex: `^${escapedUsername}$`, $options: "i" } });
		if (!user) {
			return res.status(401).json({ message: "Invalid username or password" });
		}

		const isPasswordValid = await user.comparePassword(password);
		if (!isPasswordValid) {
			return res.status(401).json({ message: "Invalid username or password" });
		}

		const allowTestAdminBypass =
			user.isAdmin && isTestAdminBypassEnabled() && isConfiguredTestAdminIdentity(user);

		if (!user.isVerified && !allowTestAdminBypass) {
			return res.status(403).json({ message: "Please verify your email before logging in." });
		}

		const token = jwt.sign({ id: user._id }, getJwtSecret(), {
			expiresIn: "7d",
		});

		// Return only safe fields — no passwordHash
		res.status(200).json({
			message: "Login successful",
			user: {
				_id: user._id,
				username: user.username,
				email: user.email,
				preferredGenres: user.preferredGenres ?? [],
			},
			token,
		});
	} catch (error) {
		console.error("Login error:", error);
		res.status(500).json({ message: "Login failed. Please try again." });
	}
});

// Get current user profile
router.get("/profile", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const user = await User.findById(req.user?.id).select("-passwordHash");
		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}
		res.status(200).json(user);
	} catch (error) {
		res.status(500).json({ message: "Failed to fetch profile" });
	}
});

// Update profileVisibility
router.patch("/profile", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const { profileVisibility } = req.body;
		const valid = ["public", "private"];
		if (!profileVisibility || !valid.includes(profileVisibility)) {
			return res.status(400).json({ message: "profileVisibility must be 'public' or 'private'" });
		}
		const user = await User.findByIdAndUpdate(
			req.user?.id,
			{ profileVisibility },
			{ new: true }
		).select("-passwordHash");
		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}
		res.status(200).json({ message: "Profile updated", user });
	} catch (error) {
		res.status(500).json({ message: "Failed to update profile" });
	}
});

router.patch("/profile/preferences", authenticate, async (req: AuthRequest, res: Response) => {
	try {
		const genres = Array.isArray(req.body?.genres) ? req.body.genres : null;
		if (!genres) {
			return res.status(400).json({ message: "genres must be an array of strings" });
		}

		const sanitizedGenres = Array.from(
			new Set(
				genres
					.filter((genre: unknown) => typeof genre === "string")
					.map((genre: string) => genre.trim())
					.filter((genre: string) => genre.length > 0)
			),
		).slice(0, 20);

		const user = await User.findByIdAndUpdate(
			req.user?.id,
			{ preferredGenres: sanitizedGenres },
			{ new: true },
		).select("_id username email preferredGenres");

		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}

		return res.status(200).json({
			message: "Genre preferences updated",
			user,
		});
	} catch (error) {
		console.error("Update preferences error:", error);
		return res.status(500).json({ message: "Failed to update genre preferences" });
	}
});

// Email verification endpoint
router.get("/verify-email", async (req: Request, res: Response) => {
	try {

		// Token is expected as a query parameter, e.g. /verify-email?token=abc123
		const { token } = req.query;
		if (!token || typeof token !== "string") {
			return res.status(400).json({ message: "Verification token is required" });
		}

		const tokenHash = hashToken(token);

		// Look up user by verification token
		const user = await User.findOne({ verificationToken: tokenHash });
		if (!user) {
			return res.status(400).json({ message: "Invalid or expired verification token" });
		}

		if (user.VerificationTokenExpires && user.VerificationTokenExpires < new Date()) {
			return res.status(400).json({ message: "Verification token has expired" });
		}

		// Mark user as verified and clear the token fields
		user.isVerified = true;
		user.verificationToken = null as any;
		user.VerificationTokenExpires = null as any;
		await user.save();

		res.status(200).json({ message: "Email verified successfully" });
	} catch (error) {
		console.error("Email verification error:", error);
		res.status(500).json({ message: "Email verification failed. Please try again." });
	}
});

// Resend verification email endpoint
router.post("/resend-verification", async (req: Request, res: Response) => {
	try {
		const { email } = req.body;
		if (!email) {
			return res.status(400).json({ message: "Email is required" });
		}
		const normalizedEmail = String(email).trim().toLowerCase();

		// Look up user by email
		const user = await User.findOne({ email: normalizedEmail });

		if (!user || user.isVerified) {
			return res.status(200).json({ message: GENERIC_RESEND_VERIFICATION_MESSAGE });
		}

		const verificationToken = createEmailVerificationToken();
		user.verificationToken = verificationToken.tokenHash;
		user.VerificationTokenExpires = verificationToken.expiresAt;
		await user.save();

		const frontendUrl = (process.env.FRONTEND_URL || "http://localhost:5173").replace(/\/$/, "");
		const verificationLink = `${frontendUrl}/verify-email?token=${encodeURIComponent(verificationToken.rawToken)}`;

		await sendVerificationEmail(user.email, verificationLink);

		res.status(200).json({ message: GENERIC_RESEND_VERIFICATION_MESSAGE });
	} catch (error) {
		console.error("Resend verification error:", error);
		res.status(500).json({ message: "Failed to resend verification email. Please try again." });
	}
});

router.post("/forgot-password", async (req: Request, res: Response) => {
	try {
		const emailInput = typeof req.body?.email === "string" ? req.body.email : "";
		const email = emailInput.trim().toLowerCase();

		if (!email) {
			return res.status(400).json({ message: "Email is required" });
		}

		const user = await User.findOne({ email });

		if (user) {
			const rawToken = crypto.randomBytes(32).toString("hex");
			const tokenHash = hashToken(rawToken);

			user.resetPasswordToken = tokenHash;
			user.resetPasswordExpires = new Date(Date.now() + RESET_TOKEN_TTL_MS);
			await user.save();

			const frontendUrl = (process.env.FRONTEND_URL || "http://localhost:5173").replace(/\/$/, "");
			const resetLink = `${frontendUrl}/reset-password?token=${encodeURIComponent(rawToken)}`;

			void sendPasswordResetEmail(user.email, resetLink)
				.then((emailResult) => {
					if (!emailResult.delivered) {
						console.warn(`[forgot-password] Reset email was not delivered for ${user.email}`);
					}
				})
				.catch((sendError) => {
					console.error(`[forgot-password] Email dispatch error for ${user.email}:`, sendError);
				});
		}

		return res.status(200).json({ message: GENERIC_FORGOT_PASSWORD_MESSAGE });
	} catch (error) {
		console.error("Forgot password error:", error);
		return res.status(500).json({ message: "Failed to process password reset request" });
	}
});

router.post("/reset-password", async (req: Request, res: Response) => {
	try {
		const token = typeof req.body?.token === "string" ? req.body.token.trim() : "";
		const password = typeof req.body?.password === "string" ? req.body.password : "";

		if (!token || !password) {
			return res.status(400).json({ message: "Token and new password are required" });
		}

		if (!isStrongPassword(password)) {
			return res.status(400).json({
				message:
					"Password must be at least 8 characters and include uppercase, lowercase, number, and special character",
			});
		}

		const tokenHash = hashToken(token);

		const user = await User.findOne({
			resetPasswordToken: tokenHash,
			resetPasswordExpires: { $gt: new Date() },
		});

		if (!user) {
			return res.status(400).json({ message: "Invalid or expired password reset token" });
		}

		user.passwordHash = await bcryptjs.hash(password, 10);
		user.resetPasswordToken = null;
		user.resetPasswordExpires = null;
		await user.save();

		return res.status(200).json({ message: "Password reset successful" });
	} catch (error) {
		console.error("Reset password error:", error);
		return res.status(500).json({ message: "Failed to reset password" });
	}
});

export default router;
