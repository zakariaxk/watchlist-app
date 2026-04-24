type RestoreFn = () => void;

export const silenceConsole = (): RestoreFn => {
	const originalLog = console.log;
	const originalWarn = console.warn;

	console.log = () => undefined;
	console.warn = () => undefined;

	return () => {
		console.log = originalLog;
		console.warn = originalWarn;
	};
};

