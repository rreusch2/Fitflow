## Xcode + TestFlight Setup (Step-by-step)

### 1) Prepare your Mac
- Install latest Xcode from the Mac App Store.
- Sign in Xcode: Xcode → Settings → Accounts → Add your Apple ID.

### 2) Create the Xcode Project
- Open Xcode → Create new iOS App → SwiftUI, Swift, iOS 17+.
- Set Bundle Identifier (e.g., com.yourname.fitflow). Keep this consistent.

### 3) Add the Fitflow code
- In Finder, open your repo folder.
- In Xcode, right-click the project → “Add Files to …” → select `FitflowApp/App`, `Core`, `Resources`, `Shared`.
- Ensure “Copy items if needed” and your target checked.
- Add `Keys.plist` to `Resources` (copy into bundle).

### 4) Add dependencies
- File → Add Package Dependencies → `https://github.com/supabase/supabase-swift` (latest).

### 5) Configure capabilities
- In the target settings → Signing & Capabilities:
  - Add HealthKit (if using), Push Notifications (later), and Background Modes if needed.

### 6) App Store Connect
- Go to `appstoreconnect.apple.com` → My Apps → New App.
- Name: Fitflow (or working title), Platform: iOS, Bundle ID: match Xcode, SKU: any unique string.
- Users & Access → add testers as needed.

### 7) Signing & Profiles
- In Xcode target → Signing & Capabilities:
  - Check “Automatically manage signing.”
  - Choose your Team.

### 8) Build & Run (Simulator and Device)
- Select a simulator (iPhone 15) → Run.
- For device: connect iPhone via USB/Wi‑Fi; trust device; select it and Run.

### 9) Archive for TestFlight
- Set Scheme to “Any iOS Device (arm64)”.
- Product → Archive.
- Organizer → Distribute App → App Store Connect → Upload.
- After processing (10–30 min), go to App Store Connect → TestFlight.

### 10) TestFlight
- Internal testing: add up to 100 members from your App Store Connect team. Immediate access.
- External testing: add testers by email; submit for Beta App Review.

### 11) Versioning
- Update `Config.App.version` and build number when you submit each build.

### 12) Common fixes
- Missing `Keys.plist`: add to bundle with real keys.
- “No such module Supabase”: ensure SPM added, clean build folder (Shift+Cmd+K).
- Signing errors: confirm correct Team and automatic signing enabled.


