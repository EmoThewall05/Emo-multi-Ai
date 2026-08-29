# 🦋 EmoMulti AI Studio

A sovereign, multi-AI vault app — one account, every provider, your own keys.

EmoMulti AI Studio is a Flutter-based Android app that brings together 25+ leading AI providers (Gemini, Claude, GPT-4o, Grok, DeepSeek, Midjourney, Runway, and more) into a single, secure vault. Built entirely from a phone, using Termux and Acode — no laptop required.

## ✨ Features

- **Sovereign API Vault** — Add your own API keys for any of 25+ AI providers (text, image, video). Keys are encrypted before they ever leave your device.
- **Bring Your Own Key (BYOK)** — Free, unlimited use when you supply your own key. No markup, no middleman.
- **Managed Access (optional)** — Don't have a key? Subscribe to Text Pro, Image Pro, Video Pro, or the all-in-one Flat plan for managed access to select models.
- **Coin Economy** — Earn daily coins, track your balance in real time, and cash out via TheWall Web3 wallet — real crypto, not IOUs.
- **Real Brand Icons** — Every provider card shows its authentic logo via the open-source simple_icons library.
- **Guest Mode** — Try the app instantly with anonymous sign-in, no email required.
- **Cyberpunk Butterfly UI** — A dark, neon-accented interface designed for clarity and speed.

### 🍳 Chef Mode
A dedicated AI cooking assistant, Kerala-focused:
- **Fridge Photo Analysis** — snap a photo of your fridge, AI detects ingredients and suggests a diet-friendly recipe
- **Kerala + Global Recipes** — recipes with a Kerala twist where possible (e.g. chammanthi instead of mayo)
- **Diet-goal aware** — weight loss, muscle gain, maintenance, diabetic-friendly; veg/non-veg/keto/intermittent fasting/kerala traditional
- **Calorie & macro estimate** — approximate calories, protein, carbs, fat per recipe
- **Voice Mode** — Text-to-Speech (`/speak`) and Speech-to-Text (`/listen`) so you can talk to Chef Mode hands-free
- **Video Recipes** (in progress) — AI-generated recipe videos via Kling AI
- **Quick filters** — 10 min, Date night, Gym diet, and more
- Powered by Claude / GPT-4o / Gemini / Grok

### 👥 Community Feed
A social layer for AI creations:
- Upload your AI-generated recipes, images, and content to a shared feed
- 5-star community rating system
- **Coin rewards** — earn 5 Emo Coins per rating received, capped at 20 ratings per post (100 coins / ₹10 max per generation)
- Public storage bucket with upload/view/delete access policies

### 🎨 Create Tab — Guided Templates
Pick a template to get started, each pre-wired to the best-fit AI provider(s):
- **Students Support** — homework help, study plans, exam prep (GPT-4o / Gemini)
- **Stress Relief** — calm conversations, mindfulness, venting (Claude)
- **Develop Ideas** — brainstorm and refine (Claude)
- **Understand & Learn** — explanations, research, deep dives (Gemini)
- **Crypto Knowledge** — market info, Web3 concepts, current data (GPT-4o / Perplexity)
- **Chef Mode** — recipes, fridge photo, Kerala dishes & more (Claude / GPT-4o / Gemini / Grok)
- **Coding & Web Dev** — build apps, debug, websites & scripts

## 🧠 Philosophy — "Nere Va Nere Po"
Transparent, non-exploitative software. Users earn real value. The platform profits only from optional subscriptions and advertising — never by quietly taking a cut of what belongs to the user.

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Postgres + Auth + RLS) |
| Encryption | AES (via the encrypt package), client-side before storage |
| Icons | simple_icons |
| Voice | Cloudflare Workers AI — Deepgram Aura-1 (TTS), Whisper large-v3-turbo (STT) |
| Video (Chef Mode) | Kling AI |
| CI/CD | GitHub Actions (Build Release APK) |
| Dev Environment | Termux + Acode on Android — no desktop used |

## 📦 Supported AI Providers

**Text:** Gemini, Anthropic (Claude), OpenAI, Grok/xAI, Perplexity, DeepSeek, Mistral, Qwen, GitHub Copilot, Meta Llama, Kimi

**Image:** Midjourney, Ideogram, FLUX, Recraft, Adobe Firefly, Nano Banana

**Video:** Veo, Kling, Runway, Luma, PixVerse, Pika, MiniMax, Seedream/Seedance

## 🗄️ Database Schema (Supabase)

- `profiles` — user profile data
- `coin_wallets` — user_id, balance, last_daily_claim_date, updated_at
- `coin_transactions` — coin earn/spend history (user_id, amount, reason, created_at)
- `cashout_requests` — crypto cash-out requests (min. 500 coins)
- `subscriptions` — active managed-tier subscriptions
- `user_api_keys` — encrypted, per-user, per-provider API keys (RLS-protected)
- `community_posts` — user_id, media_url, media_type, caption, rating_count, rating_sum, created_at
- `community_ratings` — post_id, rater_user_id, rating (unique per user/post — prevents duplicate ratings)

All tables are protected with Row Level Security — users can only ever read or write their own data. A `SECURITY DEFINER` trigger (`on_new_rating`) automatically credits the post owner 5 coins per rating, capped at 20 ratings per post.

**Storage:** `community-media` bucket (public) — authenticated upload, public view, owner-only delete.

## 💰 Subscription Tiers (Managed Access)

| Tier | Price | Access |
|---|---|---|
| Free | $0 | Gemini, Groq, Mistral — limited daily use, no key needed |
| Free (BYOK) | $0 | Unlimited use with your own API key, any provider |
| Text Pro | $4.99/mo | Managed access to select text models |
| Image Pro | $3.99/mo | Managed access to select image models |
| Video Pro | $6.99/mo | Managed access to select video models |
| Flat (All) | $9.99/mo | All three categories combined |

Premium/flagship models remain BYOK-only on managed plans to keep the economics sustainable for everyone.

## 🏗️ Build

Local builds on-device (Termux/ARM64) currently hit an aapt2 architecture mismatch and are not supported. GitHub Actions is the official build path:
Every push to main triggers Build Release APK, producing a downloadable APK artifact.
lib/
├── main.dart                  # App entry, AuthGate, VaultHomeScreen
├── login_screen.dart          # Email/password + guest login
├── supabase_config.dart       # Supabase client init
├── models/
│   └── ai_provider.dart       # AiProvider model
├── data/
│   └── provider_data.dart     # List of all 25+ AI providers
└── widgets/
├── vault_card_grid.dart       # Main provider card grid
├── app_sidebar.dart           # Desktop-style sidebar (categories, user, payment, status)
├── add_key_dialog.dart        # Encrypted "Add New Key" form
├── chat_screen.dart           # Provider chat interface
├── chef_mode_screen.dart      # Chef Mode: fridge photo, voice, recipes
├── community_tab.dart         # Community feed: upload, rate, earn coins
├── create_tab.dart            # Guided template picker
├── emo_coin_tab.dart          # Coin balance + TheWall cashout
├── profile_tab.dart           # Subscription plans, account
├── thewall_webview_screen.dart
└── generic_add_key_dialog.dart
## 👤 Author
Built by Dwin (TheWall) — part of the wider Dwin Universe ecosystem.

Releases
No releases published

Packages
No packages published

Contributors
1 (1)
@EmoThewall05 EmoThewall05

Languages
Dart 67.8% · C++ 16.5% · CMake 12% · Swift 1.8% · HTML 0.9% · C 0.9% · Other 0.1%
