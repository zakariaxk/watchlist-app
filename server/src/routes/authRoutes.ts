import { Router, Request, Response } from "express";
import bcryptjs from "bcryptjs";
import User from "../models/User";
import jwt from "jsonwebtoken";
import { authenticate, AuthRequest } from "../middleware/auth";

const router = Router();

// Register
router.post("/register", async (req: Request, res: Response) => {
	try {
		const { username, email, password, profileVisibility } = req.body;

		if (!username || !email || !password) {
			return res.status(400).json({ message: "Username, email, and password are required" });
		}

		const existingUser = await User.findOne({ $or: [{ email }, { username }] });
		if (existingUser) {
			return res.status(400).json({ message: "User already exists" });
		}

		const passwordHash = await bcryptjs.hash(password, 10);

		const newUser = new User({
			username,
			email,
			passwordHash,
			profileVisibility: profileVisibility || "public",
			// Generate email verification token and set expiration
			verificationToken: jwt.sign({ email }, process.env.JWT_SECRET || "secret", { expiresIn: "1d" }),
			VerificationTokenExpires: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours from now
			isVerified: false,
		});
		await newUser.save();

		const token = jwt.sign({ id: newUser._id }, process.env.JWT_SECRET || "secret", {
			expiresIn: "7d",
		});

		res.status(201).json({
			message: "User registered successfully",
			user: { _id: newUser._id, username: newUser.username, email: newUser.email },
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
		const { username, password } = req.body;

		if (!username || !password) {
			return res.status(400).json({ message: "Username and password are required" });
		}

		// Look up by username (case-insensitive match)
		const user = await User.findOne({ username: { $regex: `^${username}$`, $options: "i" } });
		if (!user) {
			return res.status(401).json({ message: "Invalid username or password" });
		}

		const isPasswordValid = await user.comparePassword(password);
		if (!isPasswordValid) {
			return res.status(401).json({ message: "Invalid username or password" });
		}

		if (!user.isVerified) {
			return res.status(403).json({ message: "Please verify your email before logging in." });
		}

		const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || "secret", {
			expiresIn: "7d",
		});

		// Return only safe fields — no passwordHash
		res.status(200).json({
			message: "Login successful",
			user: { _id: user._id, username: user.username, email: user.email },
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

// Email verification endpoint
router.get("/verify-email", async (req: Request, res: Response) => {
	try {

		// Token is expected as a query parameter, e.g. /verify-email?token=abc123
		const { token } = req.query;
		if (!token || typeof token !== "string") {
			return res.status(400).json({ message: "Verification token is required" });
		}

		// Look up user by verification token
		const user = await User.findOne({ verificationToken: token });
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
router.post("/auth/resend-verification", async (req: Request, res: Response) => {
	try {
		const { email } = req.body;
		if (!email) {
			return res.status(400).json({ message: "Email is required" });
		}

		// Look up user by email
		const user = await User.findOne({ email });
		if (!user) {
			return res.status(404).json({ message: "User not found" });
		}

		// If already verified, no need to resend
		if (user.isVerified) {
			return res.status(400).json({ message: "Email is already verified" });
		}

		// Generate new verification token and update user
		user.verificationToken = jwt.sign({ email }, process.env.JWT_SECRET || "secret", { expiresIn: "1d" });
		user.VerificationTokenExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
		await user.save();

		res.status(200).json({ message: "Verification email sent" });
	} catch (error) {
		console.error("Resend verification error:", error);
		res.status(500).json({ message: "Failed to resend verification email. Please try again." });
	}
});

export default router;
