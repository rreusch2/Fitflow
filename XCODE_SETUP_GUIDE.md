# 📱 Xcode Setup Guide - Step by Step

## Step 1: Create New Xcode Project

1. Open Xcode
2. Click "Create a new Xcode project"
3. Choose **iOS** → **App**
4. Fill in these settings:
   - **Product Name:** `Fitflow`
   - **Organization Identifier:** `com.rreusch.fitflow`
   - **Language:** Swift
   - **Interface:** SwiftUI
   - **Use Core Data:** ❌ (unchecked)
5. Click **Next** and choose where to save (like Desktop)
6. Click **Create**

## Step 2: Delete Default Files

Xcode creates some default files we don't need:

1. In Xcode's left sidebar (Project Navigator), **right-click** on these files and delete them:
   - `ContentView.swift` (we have our own)
   - `FitflowApp.swift` (we have our own)
2. When prompted, choose **"Move to Trash"**

## Step 3: Add Our Files to Xcode

Now we need to add all our custom files. Here's the easiest way:

### Method 1: Drag and Drop (Recommended)

1. **Open Finder** and navigate to your `/home/reid/Desktop/Fitflow/` folder
2. **Open the `FitflowApp` folder** in Finder
3. **In Xcode**, right-click on your project name (`Fitflow`) in the left sidebar
4. Choose **"Add Files to 'Fitflow'"**
5. **Navigate to** `/home/reid/Desktop/Fitflow/FitflowApp/`
6. **Select ALL folders** (`App`, `Core`, `Resources`, `Shared`)
7. **Make sure these options are checked:**
   - ✅ "Copy items if needed"
   - ✅ "Create groups" (not folder references)
   - ✅ Your target is selected
8. Click **Add**

### Method 2: Individual File Addition

If drag-and-drop doesn't work, add files one by one:

1. Right-click project name → **"Add Files to 'Fitflow'"**
2. Navigate to `/home/reid/Desktop/Fitflow/FitflowApp/App/`
3. Select `FitflowApp.swift` and `ContentView.swift`
4. Click **Add**
5. Repeat for each folder (`Core`, `Resources`, `Shared`)

## Step 4: Add Keys.plist (IMPORTANT!)

This file contains your API keys and must be added to your app bundle:

1. In Finder, go to `/home/reid/Desktop/Fitflow/FitflowApp/Resources/`
2. **Drag `Keys.plist`** directly into Xcode's Project Navigator
3. **Make sure to check:**
   - ✅ "Copy items if needed"
   - ✅ Your app target is selected
4. Click **Finish**

## Step 5: Verify File Structure

Your Xcode Project Navigator should look like this:

```
Fitflow/
├── App/
│   ├── FitflowApp.swift
│   └── ContentView.swift
├── Core/
│   ├── AI/
│   │   ├── AIService.swift
│   │   └── AIPrompts.swift
│   ├── Authentication/
│   │   └── AuthenticationService.swift
│   ├── Database/
│   │   └── DatabaseService.swift
│   └── Config.swift
├── Resources/
│   ├── DesignSystem.swift
│   └── Keys.plist
├── Shared/
│   └── Models/
│       ├── UserModels.swift
│       ├── PreferenceModels.swift
│       └── PlanModels.swift
└── Assets.xcassets (Xcode default)
```

## Step 6: Add Your API Keys

1. **In Xcode**, click on `Keys.plist` in the Project Navigator
2. **Replace the placeholder values** with your real API keys:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anon key
   - `GROK_API_KEY`: Your Grok API key
   - `OPENAI_API_KEY`: Your OpenAI API key

## Step 7: Add Supabase Dependency

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter this URL: `https://github.com/supabase/supabase-swift`
3. Click **Add Package**
4. Select **supabase-swift** and click **Add Package**

## Step 8: Test Your Setup

1. Press **Cmd+B** to build your project
2. If there are no errors, you're ready to go!
3. If you get errors, check that all files are properly added

## 🚨 Common Issues & Solutions

### "Cannot find 'Config' in scope"
- Make sure `Config.swift` is added to your project
- Check that `Keys.plist` is in your app bundle

### "No such module 'Supabase'"
- Make sure you added the Supabase Swift package dependency
- Try cleaning build folder: **Product** → **Clean Build Folder**

### Build errors about missing files
- Make sure all `.swift` files are added to your project target
- Check that file paths are correct in Xcode

## 🎉 You're Ready!

Once all files are added and building successfully, you can start:
1. Running your app in the simulator
2. Building your first UI screens
3. Testing the authentication flow
4. Connecting to your Supabase database

The foundation is solid - now build your amazing fitness app! 💪