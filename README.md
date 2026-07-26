# 🦋 EmoMulti AI Studio

**A sovereign, multi-AI vault app — one account, every provider, your own keys.**

EmoMulti AI Studio is a Flutter-based Android app that brings together 25+ leading AI providers (Gemini, Claude, GPT-4o, Grok, DeepSeek, Midjourney, Runway, and more) into a single, secure vault. Built entirely from a phone, using Termux and Acode — no laptop required.

---

## ✨ Features

- **Sovereign API Vault** — Add your own API keys for any of 25+ AI providers (text, image, video). Keys are encrypted before they ever leave your device.
- **Bring Your Own Key (BYOK)** — Free, unlimited use when you supply your own key. No markup, no middleman.
- **Managed Access (optional)** — Don't have a key? Subscribe to Text Pro, Image Pro, Video Pro, or the all-in-one Flat plan for managed access to select models.
- **Coin Economy** — Earn daily coins, track your balance in real time, and cash out via [TheWall Web3 wallet](https://github.com/EmoThewall05) — real crypto, not IOUs.
- **Real Brand Icons** — Every provider card shows its authentic logo via the open-source `simple_icons` library.
- **Guest Mode** — Try the app instantly with anonymous sign-in, no email required.
- **Cyberpunk Butterfly UI** — A dark, neon-accented interface designed for clarity and speed.

---

## 🧠 Philosophy — *"Nere Va Nere Po"*

Transparent, non-exploitative software. Users earn real value. The platform profits only from optional subscriptions and advertising — never by quietly taking a cut of what belongs to the user.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Supabase (Postgres + Auth + RLS) |
| Encryption | AES (via the `encrypt` package), client-side before storage |
| Icons | `simple_icons` |
| CI/CD | GitHub Actions (`Build Release APK`) |
| Dev Environment | Termux + Acode on Android — no desktop used |

---

## 📦 Supported AI Providers

**Text:** Gemini, Anthropic (Claude), OpenAI, Grok/xAI, Perplexity, DeepSeek, Mistral, Qwen, GitHub Copilot, Meta Llama, Kimi

**Image:** Midjourney, Ideogram, FLUX, Recraft, Adobe Firefly, Nano Banana

**Video:** Veo, Kling, Runway, Luma, PixVerse, Pika, MiniMax, Seedream/Seedance

---

## 🗄️ Database Schema (Supabase)

- `profiles` — user profile data
- `coin_wallets` — `user_id`, `balance`, `last_daily_claim_date`, `updated_at`
- `coin_transactions` — coin earn/spend history
- `cashout_requests` — crypto cash-out requests (min. 500 coins)
- `subscriptions` — active managed-tier subscriptions
- `user_api_keys` — encrypted, per-user, per-provider API keys (RLS-protected)

All tables are protected with Row Level Security — users can only ever read or write their own data.

---

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

---

## 🏗️ Build

Local builds on-device (Termux/ARM64) currently hit an `aapt2` architecture mismatch and are not supported. **GitHub Actions is the official build path:**

```bash
git push
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
    ├── vault_card_grid.dart   # Main provider card grid
    ├── app_sidebar.dart       # Desktop-style sidebar (categories, user, payment, status)
    └── add_key_dialog.dart    # Encrypted "Add New Key" form
👤 Author
Built by Dwin (TheWall) — part of the wider Dwin Universe ecosystem.
