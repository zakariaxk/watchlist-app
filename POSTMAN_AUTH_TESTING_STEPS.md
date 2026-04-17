# Postman Testing Guide for Register and Login

This guide walks you through testing your authentication endpoints step by step in Postman.

Current backend endpoints in your project:
- POST /api/auth/register
- POST /api/auth/login

Base URL (local):
- http://localhost:5001

Full URLs:
- http://localhost:5001/api/auth/register
- http://localhost:5001/api/auth/login

Important for your current code:
- Register currently expects only email and password
- Login currently expects only email and password

## 1. Start the backend first

1. Open terminal in watchlist-app/server
2. Install packages if needed:

```bash
npm install
```

3. Make sure env file exists:

```bash
cp .env.example .env
```

4. Fill .env with real values:
- PORT=5001
- MONGO_URI=your real MongoDB connection string
- JWT_SECRET=your secret string

5. Run the server:

```bash
npm run dev
```

6. Confirm server is running by checking terminal output.

## 2. Create a Postman collection

1. Open Postman
2. Click New -> Collection
3. Name it Auth Testing
4. Create two requests inside it:
- Register
- Login

## 3. Optional but recommended: create a Postman variable

1. In Postman, create an Environment (for example: Local)
2. Add variable:
- baseUrl = http://localhost:5001
3. Save

Then your request URLs can be:
- {{baseUrl}}/api/auth/register
- {{baseUrl}}/api/auth/login

## 4. Test register endpoint

Request setup:
1. Method: POST
2. URL: http://localhost:5001/api/auth/register
3. Headers:
- Content-Type: application/json
4. Body -> raw -> JSON:

```json
{
  "email": "freshman1@example.com",
  "password": "Password123"
}
```

Expected success:
- Status code: 201
- Response body should include:
- message: User registered successfully
- user object with _id and email
- token

Example success response shape:

```json
{
  "message": "User registered successfully",
  "user": {
    "_id": "...",
    "email": "freshman1@example.com"
  },
  "token": "..."
}
```

## 5. Test duplicate register (error case)

Send the same register request again with same email.

Expected result:
- Status code: 400
- Message: User already exists

## 6. Test register validation (error case)

Try missing password:

```json
{
  "email": "freshman2@example.com"
}
```

Expected result:
- Status code: 400
- Message: Email and password are required

## 7. Test login endpoint

Request setup:
1. Method: POST
2. URL: http://localhost:5001/api/auth/login
3. Headers:
- Content-Type: application/json
4. Body -> raw -> JSON:

```json
{
  "email": "freshman1@example.com",
  "password": "Password123"
}
```

Expected success:
- Status code: 200
- Response should include:
- message: Login successful
- user object with _id and email
- token

Example success response shape:

```json
{
  "message": "Login successful",
  "user": {
    "_id": "...",
    "email": "freshman1@example.com"
  },
  "token": "..."
}
```

## 8. Test login wrong password (error case)

Use wrong password:

```json
{
  "email": "freshman1@example.com",
  "password": "WrongPassword"
}
```

Expected result:
- Status code: 401
- Message: Invalid email or password

## 9. Save token for future protected routes

After successful register or login:
1. Copy token from response
2. For protected endpoints later, add header:
- Authorization: Bearer YOUR_TOKEN_HERE

## 10. Quick troubleshooting checklist

If Postman cannot connect:
- Confirm server is running
- Confirm URL uses correct port 5001
- Confirm no typo in /api/auth/register or /api/auth/login

If you get 500 errors:
- Check backend terminal logs
- Verify MONGO_URI is valid and database is reachable
- Verify JWT_SECRET is set in .env

If register/login always fails:
- Confirm JSON body format is valid
- Confirm Content-Type is application/json
- Confirm email/password fields are present

## 11. Lab demo flow (recommended)

Use this exact sequence during demo:
1. Start backend and show it running
2. Register a new user (show 201 response)
3. Try duplicate register (show 400)
4. Login with correct credentials (show 200 + token)
5. Login with wrong password (show 401)
6. Show user document exists in MongoDB

This proves all core auth requirements are working.
