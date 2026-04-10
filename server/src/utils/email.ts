import nodemailer from "nodemailer";

interface PasswordResetEmailResult {
	delivered: boolean;
}

interface VerificationEmailResult {
	delivered: boolean;
}

const getSendGridApiKey = (): string | null => {
	if (process.env.SENDGRID_API_KEY) {
		return process.env.SENDGRID_API_KEY;
	}

	if (process.env.SMTP_USER === "apikey" && process.env.SMTP_PASS) {
		return process.env.SMTP_PASS;
	}

	return null;
};

const getSmtpConfig = () => {
	const host = process.env.SMTP_HOST;
	const portValue = process.env.SMTP_PORT;
	const user = process.env.SMTP_USER;
	const pass = process.env.SMTP_PASS;
	const from = process.env.EMAIL_FROM;
	const secureValue = process.env.SMTP_SECURE;

	if (!host || !portValue || !user || !pass || !from) {
		return null;
	}

	const port = Number(portValue);
	if (!Number.isInteger(port) || port <= 0) {
		return null;
	}

	const secure = typeof secureValue === "string" ? secureValue.toLowerCase() === "true" : port === 465;

	return { host, port, user, pass, from, secure };
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
	const sendGridApiKey = getSendGridApiKey();

	const sendViaSendGridApi = async (): Promise<{ delivered: boolean }> => {
		if (!sendGridApiKey) {
			return { delivered: false };
		}

		const from = process.env.EMAIL_FROM;
		if (!from) {
			return { delivered: false };
		}

		try {
			const response = await fetch("https://api.sendgrid.com/v3/mail/send", {
				method: "POST",
				headers: {
					Authorization: `Bearer ${sendGridApiKey}`,
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					personalizations: [{ to: [{ email: params.to }] }],
					from: { email: from },
					subject: params.subject,
					content: [
						{ type: "text/plain", value: params.text },
						{ type: "text/html", value: params.html },
					],
				}),
				signal: AbortSignal.timeout(8000),
			});

			if (!response.ok) {
				const responseBody = await response.text();
				console.error(
					`[${params.logTag}] SendGrid API failed for ${params.to}: ${response.status} ${responseBody}`,
				);
				return { delivered: false };
			}

			console.log(`[${params.logTag}] Email sent via SendGrid API to ${params.to}`);
			return { delivered: true };
		} catch (error) {
			console.error(`[${params.logTag}] SendGrid API error for ${params.to}:`, error);
			return { delivered: false };
		}
	};

	if (!smtpConfig && !sendGridApiKey) {
		console.log(`[${params.logTag}] SMTP not configured. Link for ${params.to}: ${params.fallbackLink}`);
		return { delivered: false };
	}

	if (!smtpConfig && sendGridApiKey) {
		return sendViaSendGridApi();
	}

	const smtp = smtpConfig;
	if (!smtp) {
		return { delivered: false };
	}

	try {
		const transporter = nodemailer.createTransport({
			host: smtp.host,
			port: smtp.port,
			secure: smtp.secure,
			connectionTimeout: 8000,
			greetingTimeout: 8000,
			socketTimeout: 8000,
			auth: {
				user: smtp.user,
				pass: smtp.pass,
			},
		});

		await transporter.sendMail({
			from: smtp.from,
			to: params.to,
			subject: params.subject,
			text: params.text,
			html: params.html,
		});

		console.log(`[${params.logTag}] Email sent to ${params.to}`);
		return { delivered: true };
	} catch (error) {
		console.error(`[${params.logTag}] Failed to send email to ${params.to}:`, error);
		if (sendGridApiKey) {
			return sendViaSendGridApi();
		}
		return { delivered: false };
	}
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
