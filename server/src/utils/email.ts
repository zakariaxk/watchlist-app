import nodemailer from "nodemailer";

interface PasswordResetEmailResult {
	delivered: boolean;
}

interface VerificationEmailResult {
	delivered: boolean;
}

const getSmtpConfig = () => {
	const host = process.env.SMTP_HOST;
	const portValue = process.env.SMTP_PORT;
	const user = process.env.SMTP_USER;
	const pass = process.env.SMTP_PASS;
	const from = process.env.EMAIL_FROM;

	if (!host || !portValue || !user || !pass || !from) {
		return null;
	}

	const port = Number(portValue);
	if (!Number.isInteger(port) || port <= 0) {
		return null;
	}

	return { host, port, user, pass, from };
};

const sendEmail = async (params: {
	to: string;
	subject: string;
	text: string;
	html: string;
	logTag: string;
	fallbackLink: string;
}): Promise<{ delivered: boolean }> => {
	const smtpConfig = getSmtpConfig();

	if (!smtpConfig) {
		console.log(`[${params.logTag}] SMTP not configured. Link for ${params.to}: ${params.fallbackLink}`);
		return { delivered: false };
	}

	const transporter = nodemailer.createTransport({
		host: smtpConfig.host,
		port: smtpConfig.port,
		secure: smtpConfig.port === 465,
		auth: {
			user: smtpConfig.user,
			pass: smtpConfig.pass,
		},
	});

	await transporter.sendMail({
		from: smtpConfig.from,
		to: params.to,
		subject: params.subject,
		text: params.text,
		html: params.html,
	});

	return { delivered: true };
};

export const sendPasswordResetEmail = async (
	to: string,
	resetLink: string,
): Promise<PasswordResetEmailResult> => {
	return sendEmail({
		to,
		subject: "Reset your WatchIt password",
		text: `You requested a password reset. Use this link to set a new password:\n\n${resetLink}\n\nThis link expires in 1 hour. If you did not request this, you can ignore this email.`,
		html: `<p>You requested a password reset.</p><p><a href="${resetLink}">Set a new password</a></p><p>This link expires in 1 hour. If you did not request this, you can ignore this email.</p>`,
		logTag: "password-reset",
		fallbackLink: resetLink,
	});
};

export const sendVerificationEmail = async (
	to: string,
	verificationLink: string,
): Promise<VerificationEmailResult> => {
	return sendEmail({
		to,
		subject: "Verify your WatchIt account",
		text: `Welcome to WatchIt! Please verify your email by clicking this link:\n\n${verificationLink}\n\nThis link expires in 24 hours.`,
		html: `<p>Welcome to WatchIt!</p><p><a href="${verificationLink}">Verify your email</a></p><p>This link expires in 24 hours.</p>`,
		logTag: "email-verification",
		fallbackLink: verificationLink,
	});
};
