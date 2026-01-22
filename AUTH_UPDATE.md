# Authentication & Security Update

## Changes Made

### 1. Persistent Admin Authentication
- **App now checks authentication on startup** - if admin is already logged in, goes directly to user home
- **Login session persists** - admin logs in once and stays logged in throughout app usage
- **No forced sign-out** - removed the automatic sign-out behavior from auth_gate

### 2. Password-Protected Question Management
- **New password gate** for accessing admin questions page
- **Hardcoded password:** `reallygoodpassword`
- **User flow:**
  1. Admin logs in once with Firebase email/password (persists)
  2. Users at booth can play quiz and submit scores (works because admin is logged in)
  3. To access question management, click person icon → enter password
  4. Password prevents unauthorized question changes

### 3. Score Submission Security
- **No Cloud Functions needed** - uses Firestore rules directly
- **Works automatically** - since admin account is logged in, quiz_page can write to Firestore
- **Firestore rules allow:** Authenticated email/password users (admins) have full write access
- **Users at booth:** Can submit scores because admin auth is active in background

## App Flow

### Initial Setup (One Time)
1. Admin opens app
2. If not logged in, sees login page
3. Logs in with Firebase email/password
4. Session persists - admin stays logged in

### Regular Booth Usage
1. App opens → Already logged in (admin session active)
2. Shows user home page automatically
3. Users enter code → Select category → Take quiz → Submit score
4. Score writes succeed because admin is authenticated

### Question Management
1. Click person icon in app bar
2. Enter password: `reallygoodpassword`
3. Access admin questions page
4. Can upload CSV, manage categories, etc.

## Security Model

**Two-Layer Security:**
1. **Firebase Authentication** - Admin account logged in (email/password provider)
   - Firestore rules trust this auth method
   - Enables write access to database

2. **Password Wall** - Hardcoded password for question management
   - Prevents booth users from modifying questions
   - Simple but effective for supervised booth environment

**Why This Works:**
- Firestore rules check: `request.auth.token.firebase.sign_in_provider == 'password'`
- Admin is logged in with password provider → Has write access
- Quiz page writes scores using admin's authentication
- Password wall stops casual users from accessing admin features

## Files Modified

1. **main.dart**
   - Added `AppRoot` widget to check auth state on startup
   - Routes to login only if not authenticated
   - Routes to user home if already logged in

2. **auth_gate.dart**
   - Removed forced sign-out behavior
   - Simplified to just show login page
   - Keeps user logged in after authentication

3. **admin_password_gate.dart** (NEW)
   - Password protection for question management
   - Simple password check before allowing access
   - Hardcoded password: `reallygoodpassword`

## Testing Checklist

- [ ] Fresh install: Shows login page
- [ ] Log in with admin credentials → Goes to user home
- [ ] Close and reopen app → Skips login, goes to user home
- [ ] Enter code → Take quiz → Score submits successfully
- [ ] Click person icon → Asks for password
- [ ] Enter correct password → Access admin questions page
- [ ] Wrong password → Shows error, stays locked
- [ ] Upload questions → Works without issues

## Notes

- **Password is hardcoded** in `admin_password_gate.dart` line 17
- **To change password:** Edit the `_correctPassword` constant
- **Admin credentials:** Use Firebase email/password account (same as admin minigame app)
- **No logout button needed** - admin stays logged in continuously during event
