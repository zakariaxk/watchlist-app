// This file is for declaring modules that TypeScript doesn't recognize by default, such as CSS imports.
// It allows us to import CSS files without TypeScript throwing errors about missing modules.
declare module '*.css';
declare module '*.scss';
declare module '*.sass';