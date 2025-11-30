# OTP Verification Before Signup - cURL Examples

## Base URL
Replace `localhost:3000` with your actual server URL if different.

---

## Complete Flow

### Step 1: Request OTP

**With Phone Number:**
```bash
curl -X POST http://localhost:3000/users/otp_verifications/request \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890"
  }'
```

**With Email:**
```bash
curl -X POST http://localhost:3000/users/otp_verifications/request \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com"
  }'
```

**Success Response:**
```json
{
  "status": {
    "code": 200,
    "message": "OTP has been sent successfully."
  },
  "data": {
    "verification_token": "abc123def456...",
    "otp_code": "123456"  // Only in development mode
  }
}
```

**Error Response (User Already Exists):**
```json
{
  "status": {
    "code": 422,
    "message": "User with this phone number or email already exists"
  }
}
```

---

### Step 2: Verify OTP

```bash
curl -X POST http://localhost:3000/users/otp_verifications/verify \
  -H "Content-Type: application/json" \
  -d '{
    "verification_token": "abc123def456...",
    "otp_code": "123456"
  }'
```

**Success Response:**
```json
{
  "status": {
    "code": 200,
    "message": "OTP verified successfully."
  },
  "data": {
    "verification_token": "abc123def456...",
    "verified": true
  }
}
```

**Error Response:**
```json
{
  "status": {
    "code": 422,
    "message": "Invalid or expired OTP code"
  }
}
```

---

### Step 3: Complete Signup

**With Phone Number:**
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "verification_token": "abc123def456...",
      "name": "John Doe",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**With Email:**
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "verification_token": "abc123def456...",
      "name": "Jane Smith",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

**Note:** The `phone_number` or `email` will be automatically extracted from the verified OTP, so you don't need to include them in the signup request.

**Success Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Signed up successfully."
  },
  "data": {
    "id": "1",
    "email": "user@example.com",
    "name": "John Doe",
    "phone_number": "+1234567890"
  }
}
```

**Error Response (OTP Not Verified):**
```json
{
  "status": {
    "code": 422,
    "message": "OTP must be verified before signup"
  }
}
```

**Error Response (Missing Verification Token):**
```json
{
  "status": {
    "code": 422,
    "message": "Verification token is required. Please verify OTP first."
  }
}
```

---

## Complete Example Flow

```bash
# Step 1: Request OTP
RESPONSE=$(curl -s -X POST http://localhost:3000/users/otp_verifications/request \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+1234567890"}')

# Extract verification_token and otp_code (in development)
VERIFICATION_TOKEN=$(echo $RESPONSE | grep -o '"verification_token":"[^"]*"' | cut -d'"' -f4)
OTP_CODE=$(echo $RESPONSE | grep -o '"otp_code":"[^"]*"' | cut -d'"' -f4)

echo "Verification Token: $VERIFICATION_TOKEN"
echo "OTP Code: $OTP_CODE"

# Step 2: Verify OTP
curl -X POST http://localhost:3000/users/otp_verifications/verify \
  -H "Content-Type: application/json" \
  -d "{
    \"verification_token\": \"$VERIFICATION_TOKEN\",
    \"otp_code\": \"$OTP_CODE\"
  }"

# Step 3: Complete Signup
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"verification_token\": \"$VERIFICATION_TOKEN\",
      \"name\": \"John Doe\",
      \"password\": \"password123\",
      \"password_confirmation\": \"password123\"
    }
  }"
```

---

## Notes

- **OTP Expiration**: OTP codes expire after 10 minutes
- **Development Mode**: In development, OTP codes are returned in the response for testing
- **Production Mode**: In production, OTP codes are NOT returned - check SMS/email
- **Verification Token**: Single-use token that links OTP verification to signup
- **Automatic Cleanup**: OTP verification is deleted after successful signup
- **User Check**: System prevents creating accounts for phone numbers/emails that already exist

---

## Error Scenarios

### 1. Requesting OTP for existing user
```bash
curl -X POST http://localhost:3000/users/otp_verifications/request \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+1234567890"}'
# Returns: "User with this phone number or email already exists"
```

### 2. Verifying with wrong OTP
```bash
curl -X POST http://localhost:3000/users/otp_verifications/verify \
  -H "Content-Type: application/json" \
  -d '{
    "verification_token": "abc123...",
    "otp_code": "999999"
  }'
# Returns: "Invalid or expired OTP code"
```

### 3. Signup without verification
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Doe",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
# Returns: "Verification token is required. Please verify OTP first."
```

### 4. Signup with unverified token
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "verification_token": "unverified_token",
      "name": "John Doe",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
# Returns: "OTP must be verified before signup"
```

