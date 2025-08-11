# Fitflow - AI-Powered Fitness Assistant

An iOS app built with SwiftUI that provides personalized workout plans, meal recommendations, and motivation through intelligent user profiling and adaptive learning.

## Tech Stack

- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Supabase (PostgreSQL, Auth, Edge Functions)
- **AI Integration**: Grok API + OpenAI (fallback)
- **Health Data**: Apple HealthKit
- **Architecture**: MVVM with Combine

## Project Structure

```
FitflowApp/
├── App/                    # App entry point and main views
├── Core/                   # Core services and utilities
│   ├── Authentication/     # Auth service and views
│   ├── Database/          # Supabase integration
│   └── AI/                # AI service and prompt management
├── Features/              # Feature-specific modules
│   ├── Onboarding/        # User onboarding flow
│   ├── Dashboard/         # Main dashboard
│   ├── Plans/             # Workout and meal plans
│   └── Profile/           # User profile and settings
├── Shared/                # Shared components and utilities
│   ├── Models/            # Data models
│   ├── Views/             # Reusable UI components
│   └── Extensions/        # Swift extensions
└── Resources/             # Assets, colors, fonts
```

## Development Timeline

- **Weeks 1-2**: Setup & Learning
- **Weeks 3-4**: Onboarding Flow
- **Weeks 5-6**: AI Integration
- **Weeks 7-8**: Core Features
- **Weeks 9-10**: Polish & Testing
- **Weeks 11-12**: Launch Preparation

## Getting Started

1. Open `FitflowApp.xcodeproj` in Xcode
2. Set up Supabase project and add credentials to `Config.swift`
3. Add AI API keys to environment
4. Build and run on iOS Simulator or device

## MVP Features

- User onboarding with preference collection
- Personalized workout plan generation
- Personalized meal plan generation
- Basic progress tracking
- Clean, professional UI/UX

## Next Steps

After MVP launch, we'll add:
- AI chatbot with personality
- Advanced progress tracking
- Social features
- Premium subscription model

## Docs

- `PRODUCT_PLAN.md`: Strategy, decisions, and roadmap
- `TESTING_SETUP_XCODE.md`: How to set up Xcode and TestFlight