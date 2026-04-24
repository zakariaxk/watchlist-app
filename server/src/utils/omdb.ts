type OmdbJson = Record<string, unknown>;

type OmdbFailureCode =
	| "OMDB_RATE_LIMIT_REACHED"
	| "OMDB_UNAVAILABLE"
	| "OMDB_CONFIGURATION_ERROR";

export type OmdbFailure = {
	status: number;
	body: {
		message: string;
		code?: OmdbFailureCode;
	};
};

export type OmdbResult =
	| {
			ok: true;
			data: OmdbJson;
	  }
	| {
			ok: false;
			error: OmdbFailure;
	  };

type FetchOmdbOptions = {
	notFoundMessage: string;
	notFoundStatus?: number;
};

const RATE_LIMIT_PATTERN = /request limit reached|limit reached|too many requests/i;
const CONFIGURATION_PATTERN = /invalid api key|no api key provided/i;

const buildUnavailableFailure = (): OmdbFailure => ({
	status: 503,
	body: {
		code: "OMDB_UNAVAILABLE",
		message: "Movie data is temporarily unavailable. Please try again later.",
	},
});

const getOmdbErrorMessage = (data: OmdbJson | null): string | null => {
	const message = data?.["Error"];

	if (typeof message !== "string") {
		return null;
	}

	const trimmed = message.trim();
	return trimmed ? trimmed : null;
};

const classifyOmdbError = (
	omdbError: string | null,
	{ notFoundMessage, notFoundStatus = 404 }: FetchOmdbOptions
): OmdbFailure => {
	if (omdbError && RATE_LIMIT_PATTERN.test(omdbError)) {
		return {
			status: 429,
			body: {
				code: "OMDB_RATE_LIMIT_REACHED",
				message: "OMDb daily request limit reached. Please try again later.",
			},
		};
	}

	if (omdbError && CONFIGURATION_PATTERN.test(omdbError)) {
		return {
			status: 503,
			body: {
				code: "OMDB_CONFIGURATION_ERROR",
				message: "Movie data is temporarily unavailable. Please try again later.",
			},
		};
	}

	return {
		status: notFoundStatus,
		body: { message: omdbError || notFoundMessage },
	};
};

const readOmdbJson = async (
	response: Awaited<ReturnType<typeof fetch>>
): Promise<OmdbJson | null> => {
	try {
		return (await response.json()) as OmdbJson;
	} catch {
		return null;
	}
};

export const fetchOmdbJson = async (
	url: string,
	options: FetchOmdbOptions
): Promise<OmdbResult> => {
	try {
		const response = await fetch(url);
		const data = await readOmdbJson(response);

		if (!response.ok) {
			const omdbError = getOmdbErrorMessage(data);
			return {
				ok: false,
				error: omdbError ? classifyOmdbError(omdbError, options) : buildUnavailableFailure(),
			};
		}

		if (!data) {
			return { ok: false, error: buildUnavailableFailure() };
		}

		if (data["Response"] === "False") {
			return {
				ok: false,
				error: classifyOmdbError(getOmdbErrorMessage(data), options),
			};
		}

		return { ok: true, data };
	} catch {
		return { ok: false, error: buildUnavailableFailure() };
	}
};
