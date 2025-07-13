# Fitflow Setup Instructions

## 🔑 API Keys Setup

You now have a secure system for managing your API keys! Here's how to set it up:

### 1. Update Your Keys.plist File

Open `FitflowApp/Resources/Keys.plist` and replace the placeholder values with your actual keys:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SUPABASE_URL</key>
	<string>https://your-project-id.supabase.co</string>
	<key>SUPABASE_ANON_KEY</key>
	<string>your-supabase-anon-key-here</string>
	<key>GROK_API_KEY</key>
	<string>your-grok-api-key-here</string>
	<key>OPENAI_API_KEY</key>
	<string>your-openai-api-key-here</string>
</dict>
</plist>
```

### 2. Security Features ✅

- **Keys.plist is in .gitignore** - Your API keys will never be committed to version control
- **Secure key loading** - Config.swift safely reads from the plist file
- **Runtime validation** - App will crash with helpful error if keys are missing
- **Environment-specific** - Easy to have different keys for development/production

## 🗄️ Database Setup

### 1. Run the SQL Schema

1. Go to your Supabase dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the entire contents of `database_schema.sql`
4. Click **"Run"**

This will create:
- All 8 database tables
- Proper relationships and constraints
- Row Level Security policies
- Performance indexes
- Helper functions

### 2. Verify Setup

After running the SQL, you should see these tables in your Supabase dashboard:
- `users`
- `workout_plans`
- `meal_plans`
- `user_progress`
- `chat_sessions`
- `goals`
- `ai_usage`
- `subscription_history`

## 📱 Xcode Project Setup

### 1. Create New Xcode Project

1. Open Xcode
2. Create new project
3. Choose **iOS** → **App**
4. Set these options:
   - **Product Name**: Fitflow
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Minimum Deployment**: iOS 17.0

### 2. Add Project Files

1. Copy all the `FitflowApp/` folder contents into your Xcode project
2. Make sure to add `Keys.plist` to your project bundle (drag into Xcode)
3. Verify the file structure matches what we created

### 3. Add Dependencies

Add these Swift Package Manager dependencies:

1. **Supabase Swift SDK**
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest

2. **Optional: Additional networking libraries if needed**

### 4. Configure Info.plist

Add these permissions to your `Info.plist`:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Fitflow uses health data to provide personalized workout and nutrition recommendations.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Fitflow can log your workouts to Apple Health.</string>
```

## 🧪 Testing Your Setup

### 1. Test Database Connection

Run this in your app to test Supabase connection:

```swift
// In a test view or button action
Task {
    let dbService = DatabaseService.shared
    // This should connect without errors
}
```

### 2. Test AI Integration

```swift
// Test AI service (make sure you have API keys set up)
let aiService = AIService.shared
// Check that keys are loaded properly
```

### 3. Test Authentication

```swift
// Test auth service
let authService = AuthenticationService()
// Try creating a test user
```

## 🚀 Next Development Steps

### Phase 1: Core Views (Week 1)
1. **Authentication Views**
   - Login screen
   - Sign up screen
   - Password reset

2. **Onboarding Flow**
   - Welcome screen
   - Preferences collection
   - Goal setting

### Phase 2: Main Features (Week 2-3)
1. **Dashboard**
   - Today's plan display
   - Progress overview
   - Quick actions

2. **Plan Generation**
   - Workout plan creation
   - Meal plan creation
   - AI integration testing

### Phase 3: Polish (Week 4)
1. **UI/UX Refinement**
2. **Testing and Bug Fixes**
3. **App Store Preparation**

## 🔧 Development Tips

### Debugging
- Use `Config.Debug.enableMockData = true` for testing without API calls
- Check console logs for database connection issues
- Verify API keys are loaded correctly

### Performance
- AI responses are cached automatically
- Database queries are optimized with indexes
- Use mock data during development to save API costs

### Security
- Never commit `Keys.plist` to version control
- Use different API keys for development/production
- Test Row Level Security policies

## 📞 Need Help?

If you run into issues:

1. **Database Issues**: Check Supabase dashboard logs
2. **API Issues**: Verify keys in Keys.plist
3. **Build Issues**: Make sure all files are added to Xcode project
4. **Runtime Issues**: Check console logs for specific errors

## 🎉 You're Ready!

Your Fitflow app foundation is now complete and secure! The architecture is production-ready and will scale as your user base grows.

**Key Benefits of This Setup:**
- ✅ Secure API key management
- ✅ Production-ready database schema
- ✅ Scalable AI integration
- ✅ Professional code architecture
- ✅ Comprehensive error handling
- ✅ Performance optimizations built-in

Start building your UI views and connect them to the services we've created. The foundation will handle all the complex backend logic for you!

Good luck with your launch! 🚀