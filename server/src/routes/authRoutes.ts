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

// Login
router.post("/login", async (req: Request, res: Response) => {
	try {
		const { email, password } = req.body;

		if (!email || !password) {
			return res.status(400).json({ message: "Email and password are required" });
		}

		const user = await User.findOne({ email });
		if (!user) {
			return res.status(401).json({ message: "Invalid email or password" });
		}

		const isPasswordValid = await user.comparePassword(password);
		if (!isPasswordValid) {
			return res.status(401).json({ message: "Invalid email or password" });
		}

		const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET || "secret", {
			expiresIn: "7d",
		});

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

export default router;
