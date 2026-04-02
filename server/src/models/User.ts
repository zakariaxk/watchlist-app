import mongoose from "mongoose";
import bcryptjs from "bcryptjs";

export interface IUser extends mongoose.Document {
	username: string;
	email: string;
	passwordHash: string;
	profileVisibility: string;
	createdAt: Date;
	isVerified: boolean;
	verificationToken: string;
	VerificationTokenExpires: Date;
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
		profileVisibility: {
			type: String,
			default: "public",
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
