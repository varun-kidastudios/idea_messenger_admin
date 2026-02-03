# idea_messenger Admin Portal

iOS admin application to monitor and view all users, chats, and messages from the idea_messenger Firebase backend.

## Features

- ✅ **User Management**: View all users (authenticated and anonymous) with chat counts
- ✅ **Chat Monitoring**: Browse all chats organized by category
- ✅ **Message Viewing**: Read all messages with full metadata
- ✅ **Media Support**: Decode and display Base64-encoded images and audio
- ✅ **Real-time Updates**: Live data streaming from Firestore
- ✅ **Search & Filter**: Find users and filter chats by category
- ✅ **iOS Native Design**: Beautiful Cupertino-style interface

## Prerequisites

1. **Firebase Project**: This app connects to the same Firebase project as idea_messenger
2. **Admin Access**: You need to update Firestore security rules with your admin UID
3. **iOS Development**: Xcode and iOS development environment

## Setup Instructions

### 1. Firebase Configuration

The app is already configured to use your Firebase project `ideade-a19cc`. The configuration file `lib/firebase_options.dart` has been generated.

### 2. Update Firestore Security Rules

**IMPORTANT**: Since you want to use the app without authentication, you need to update your Firestore rules to allow read access without a UID check.

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ideaDe (ideade-a19cc)**
3. Navigate to **Firestore Database** → **Rules**
4. Update the rules to allow public read access for the admin paths (or all paths if preferred):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 1. User Data Sync
    match /users/{userId} {
      // Allow any authenticated user (inc. anonymous) to manage their own folder
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /chats/{chatId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // 2. Admin Portal Access
    match /{allPaths=**} {
      allow read: if true; 
    }
  }
}
```

5. **Publish** the updated rules

### 3. iOS Configuration

The app requires URL schemes for Google Sign-In. You need to add the `REVERSED_CLIENT_ID` from your `GoogleService-Info.plist`:

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Download `GoogleService-Info.plist` from Firebase Console:
   - Go to Project Settings → iOS apps
   - Download the config file
   - Drag it into Xcode under `Runner` folder

3. Find the `REVERSED_CLIENT_ID` in `GoogleService-Info.plist`

4. Add it as a URL scheme:
   - Select **Runner** target → **Info** tab
   - Expand **URL Types**
   - Click **+** to add a new URL type
   - Set **URL Schemes** to the `REVERSED_CLIENT_ID` value

### 4. Run the App

```bash
# Get dependencies
flutter pub get

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Or build for physical device
flutter build ios
```

## App Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── models/
│   ├── admin_user.dart               # User data model
│   ├── chat.dart                     # Chat data model
│   └── message.dart                  # Message data model
├── services/
│   ├── firebase_service.dart         # Firestore queries
│   └── media_decoder_service.dart    # Base64 decoding
├── providers/
│   ├── auth_provider.dart            # Authentication state
│   ├── users_provider.dart           # Users data & search
│   └── chats_provider.dart           # Chats & messages data
└── screens/
    ├── login_screen.dart             # Admin login
    ├── users_list_screen.dart        # All users list
    ├── chats_list_screen.dart        # User's chats
    └── chat_detail_screen.dart       # Chat messages
```

## Data Structure

The app reads from this Firestore structure:

```
users/
  {userId}/
    chats/
      {chatId}/
        - id, title, createdAt, updatedAt, categoryId
        messages/
          {messageId}/
            - id, text, type, timestamp, isMe
            - mediaContent (Base64)
            - tags, keywords
```

## Features Breakdown

### Users List Screen
- Displays all users with chat counts
- Search by email or UID
- Pull-to-refresh
- Tap to view user's chats

### Chats List Screen
- Shows all chats for selected user
- Filter by category (YouTube, Finance, DIY, Tech, etc.)
- Color-coded category badges
- Message counts and timestamps
- Tap to view chat messages

### Chat Detail Screen
- All messages in chronological order
- **Text messages**: Full text with timestamps
- **Images**: Decoded from Base64, tap to view full-screen
- **Voice messages**: Audio player with play/pause controls
- **Metadata**: Tags and keywords displayed as chips
- Long-press to copy message text

## Media Handling

The app handles Base64-encoded media from the main app:

- **Images**: Decoded and displayed inline, with full-screen viewer
- **Audio**: Decoded to temporary files and played with `audioplayers`
- **Error handling**: Graceful fallback for corrupted media

## Security Notes

⚠️ **This app has read access to ALL user data**

- Only install on authorized admin devices
- Keep your admin UID secure
- Do not share the app with unauthorized users
- Consider adding additional security layers (e.g., PIN code)

## Troubleshooting

### "Permission denied" errors
- Ensure you've updated Firestore rules with your admin UID
- Verify you're signed in with the correct account

### Google Sign-In not working
- Check that `GoogleService-Info.plist` is in the Xcode project
- Verify URL schemes are configured correctly
- Ensure Google Sign-In is enabled in Firebase Console

### Images/Audio not loading
- Check that the Base64 data is valid
- Verify the media content exists in Firestore
- Check console logs for decoding errors

### No users/chats showing
- Verify Firebase connection is working
- Check that users have synced data from the main app
- Ensure Firestore rules allow read access

## Development

Built with:
- Flutter SDK
- Firebase (Auth, Firestore)
- Riverpod (State Management)
- Cupertino Widgets (iOS Design)
- audioplayers (Audio Playback)

## License

Private - Authorized Use Only
