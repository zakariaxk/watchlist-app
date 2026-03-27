import mongoose from "mongoose";
import bcryptjs from "bcryptjs";

export interface IUser extends mongoose.Document {
	email: string;
	password: string;
	comparePassword(password: string): Promise<boolean>;
}

const userSchema = new mongoose.Schema(
	{
		email: {
			type: String,
			required: true,
			unique: true,
			lowercase: true,
			trim: true,
		},
		password: {
			type: String,
			required: true,
		},
	},
	{
		timestamps: true,
	}
);

// Hash password before saving
userSchema.pre("save", async function () {
	if (!this.isModified("password")) {
		return;
	}

	const salt = await bcryptjs.genSalt(10);
	this.password = await bcryptjs.hash(this.password, salt);
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (password: string) {
	return await bcryptjs.compare(password, this.password);
};

export default mongoose.model<IUser>("User", userSchema);
