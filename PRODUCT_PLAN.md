## Fitflow Product Plan and Engineering Notes

### Vision
Build a personalized, AI-powered wellness companion with a clean, modern UI and an adaptive experience that matches each user’s vibe, goals, and interests.

### Personalization Principles
- Use explicit preference signals (goals, activities, communication style) to drive UI vibe and content.
- Avoid gendered UI assumptions; map to vibes like energetic, calm, minimal, playful.
- Keep onboarding under 60 seconds with optional advanced steps.

### MVP Scope (current)
- Authentication, Onboarding, Main Tabs.
- Dynamic theming mapped from motivation style + activities.
- Daily feed of personalized motivational images + captions (mock images now, real gen later).
- AI plan generation scaffolding (workout/meal) via Grok/OpenAI.

### Feed Strategy (Phase 1: Images)
- Items per day: 5–10 personalized image cards with short motivational text.
- Text generated from LLM with user context; images placeholder initially.
- Topics: mindset, business, relationships + top 1–2 activities.
- Caching per day; regenerate on next day or manual refresh.

### Image Generation Options
1) Local open-weights model (e.g., FLUX.1-dev) for non-commercial/dev use.
   - License: flux-1-dev-non-commercial-license (non-commercial only). OK for dev; not for production monetization.
   - Requirements: modern GPU (>= 16GB VRAM recommended); can CPU-offload but slow.
   - Flow: backend cron builds prompts → generates → uploads to storage → app fetches signed URLs.
2) Hosted APIs (e.g., fal.ai, replicate, mystic.ai) or Runway/Luma later for videos.
   - Pros: scale, speed, no infra; Cons: cost. Gate with daily caps.

Recommended: start with hosted image gen for reliability, then evaluate local if you add a GPU server. For development, local runs on your PC are possible but slower.

### Cost & Caps (initial recommendation)
- Free: 2 image items/day personalized; Pro: 10/day at higher quality.
- Start caps low; increase after we monitor costs.

### Notifications
- Opt-in push during onboarding. Default daily motivational push at user’s chosen time window (9–11am if not set).

### Accessibility
- Captions/alt text always included for images.

### Data & Privacy
- Explicit opt-in for deeper personalization (using progress, notes). Add a toggle in settings; store a boolean flag.
- No medical advice; add disclaimers in profile/about.

### Roadmap
- Phase 1: Image feed + basic plans + chat stub.
- Phase 2: Real image generation pipeline + likes/saves + share.
- Phase 3: Video generation for hero items + AI coach improvements.
- Phase 4: Monetization tiers and paywall.

### Apple Deployment (brief)
- Create App ID in App Store Connect; set bundle ID from Xcode project settings.
- Enable Push Notifications and HealthKit in capabilities.
- Use TestFlight for internal (up to 100) then external beta.

### Engineering TODO (short)
- FeedService (API def) [added], storage plumbing, signed URL pattern.
- Push permission request + scheduling.
- Settings toggles: vibe, deeper personalization opt-in.
- Error toasts + retry for feed.

### Backend Notes (OpenAI Images)
- Edge Function path: `/images/generate` (scaffold added in `supabase/functions/images/generate/index.ts`).
- Env var: `OPENAI_API_KEY` set in Supabase project.
- For base64 responses, upload to Storage and return signed URL (future step).


