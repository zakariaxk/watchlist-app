import mongoose from "mongoose";
import bcryptjs from "bcryptjs";

export interface IUser extends mongoose.Document {
	username: string;
	email: string;
	passwordHash: string;
	isAdmin: boolean;
	profileVisibility: string;
	preferredGenres: string[];
	createdAt: Date;
	isVerified: boolean;
	verificationToken?: string | null;
	VerificationTokenExpires?: Date | null;
	resetPasswordToken?: string | null;
	resetPasswordExpires?: Date | null;
	comparePassword(plaintext: string): Promise<boolean>;
}

const userSchema = new mongoose.Schema(
	{
		username: {
			type: String,
			required: true,
			unique: true,
			trim: true,
		},
		email: {
			type: String,
			required: true,
			unique: true,
			lowercase: true,
			trim: true,
		},
		passwordHash: {
			type: String,
			required: true,
		},
		isAdmin: {
			type: Boolean,
			default: false,
		},
		profileVisibility: {
			type: String,
			default: "public",
		},
		preferredGenres: {
			type: [String],
			default: [],
		},
		isVerified: {
			type: Boolean,
			default: false,
		},
		verificationToken: {
			type: String,
		},
		VerificationTokenExpires: {
			type: Date,
		},
		resetPasswordToken: {
			type: String,
		},
		resetPasswordExpires: {
			type: Date,
		},
	},
	{
		timestamps: true,
	}
);

// Compare a plaintext password against the stored hash
userSchema.methods.comparePassword = async function (plaintext: string): Promise<boolean> {
	return bcryptjs.compare(plaintext, this.passwordHash);
};

export default mongoose.model<IUser>("User", userSchema);
