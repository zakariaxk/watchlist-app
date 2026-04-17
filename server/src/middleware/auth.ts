import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";
import { getJwtSecret } from "../config/env";

export interface AuthRequest extends Request {
	user?: { id: string };
}

export const authenticate = (req: AuthRequest, res: Response, next: NextFunction) => {
	const token = req.headers.authorization?.split(" ")[1];

	if (!token) {
		return res.status(401).json({ message: "No token provided" });
	}

	try {
		const decoded = jwt.verify(token, getJwtSecret()) as {
			id: string;
		};
		req.user = { id: decoded.id };
		next();
	} catch (error) {
		res.status(401).json({ message: "Invalid token" });
	}
};
