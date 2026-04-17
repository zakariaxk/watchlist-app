const isProduction = process.env.NODE_ENV === "production";

export const getRequiredEnv = (name: string): string => {
	const value = process.env[name];
	if (!value) {
		throw new Error(`${name} is required`);
	}
	return value;
};

export const getJwtSecret = (): string => {
	const jwtSecret = process.env.JWT_SECRET;
	if (jwtSecret) {
		return jwtSecret;
	}

	if (isProduction) {
		throw new Error("JWT_SECRET is required in production");
	}

	return "secret";
};

export const getAllowedOrigins = (): string[] => {
	const configured = process.env.CORS_ORIGINS;
	if (configured) {
		return configured
			.split(",")
			.map((origin) => origin.trim())
			.filter((origin) => origin.length > 0);
	}

	if (isProduction) {
		throw new Error("CORS_ORIGINS is required in production");
	}

	return [
		"http://localhost:5173",
		"http://localhost:5001",
		"http://10.0.2.2:5001",
		"http://192.241.131.53",
		"http://192.241.131.53:5001",
	];
};
