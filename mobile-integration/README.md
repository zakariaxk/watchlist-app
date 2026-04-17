# Mobile Integration

This Flutter app should point to the same backend API used by the website so both clients use the same MongoDB data.

## API Configuration

Set the API URL with `--dart-define`:

```bash
flutter run --dart-define=WATCHIT_API_URL=http://YOUR_SERVER:5001/api
```

If `/api` is omitted, the app will append it automatically.

## Defaults

If `WATCHIT_API_URL` is not provided, the app uses the same backend as the website:

- `http://watch-it.xyz/api`

## CORS Note

The deployed API currently only accepts requests that include `Origin: http://watch-it.xyz`.
The mobile app now sends this header automatically for native requests as a compatibility workaround.
Long-term, deploy the server CORS update that allows requests with no `Origin` header (native/mobile).

## Examples

Use local backend from Android emulator:

```bash
flutter run --dart-define=WATCHIT_API_URL=http://10.0.2.2:5001/api
```

Use deployed backend (same as website):

```bash
flutter run --dart-define=WATCHIT_API_URL=https://api.yourdomain.com/api
```
