# हर दिन (Har Din) — App Context

**What it is:** A Hindi-first Flutter app for browsing, customizing, and sharing festival status images, greetings, and quotes — for every Indian festival and community, not tied to one religion. Tagline: "Har Din, Kuch Share Karo."

**Current stage:** Front-end MVP with mock/local data only. **No backend, no APIs, no accounts.** Everything runs offline from bundled assets and in-memory state. Built to get a functional, good-looking app into the Play Store first; a second release will wire up real APIs and swap mock data for live data without changing the UI structure.

---

## Tech stack

- Flutter (Dart), Material 3
- Fonts: **Poppins** (Latin) + **Baloo 2** (Devanagari fallback) — bundled locally, no runtime download
- Icons: Material icons for navigation/UI chrome, **FontAwesome** (`font_awesome_flutter`, pinned to v10.x for the classic `IconData` API) for content/fallback icons
- Packages: `shimmer` (loading skeletons), `share_plus` (native share sheet), `flutter_launcher_icons`
- No state management library — a couple of small `ValueNotifier` singletons (e.g. `AppLanguageController`) for the few things that need to be global

---

## Brand

| Token | Hex |
|---|---|
| Primary / CTA | `#F45A0A` |
| Primary Dark | `#D94300` |
| Secondary (Golden) | `#F4B942` |
| Text Primary (Dark Brown) | `#3A2418` |
| Text Secondary (Brown Grey) | `#75665D` |
| Background | `#FFFFFF` (white — except Home's category grid, which sits on warm cream `#FBEEDA` intentionally) |
| Border | `#E8DCCB` |

Design principle: orange is reserved for important actions only (CTAs, active states) — the rest of the UI stays white/cream so it doesn't read as over-orange. A little festive decoration (soft glow accents) is used sparingly, not plastered on every screen.

---

## App flow / screens

**Splash** → **Onboarding** (logo, tagline, illustration, "शुरू करें" button, "already have an account? login" link — link currently shows a toast, no real login flow exists) → **Root shell** (bottom nav + drawer).

### Bottom nav (4 tabs + raised center action)
होम | फेस्टिवल | **+ पोस्ट करें** (raised, opens Create Post) | सेव | प्रोफाइल

### Home
- Top bar: hamburger (opens the side drawer — **now functional**), horizontal wordmark logo, notification bell, small avatar
- **Promo banner carousel** — 4 pre-made banner images (auto-rotates every 5s, swipeable), each links to a real destination (Diwali gallery, Customize, Feed, Share hub)
- "श्रेणियां / Categories" heading banner (image asset)
- **35-category grid** — each tile shows a flat icon (from `assets/categories_icons/`) + a label in **whichever language is set in Settings** (Hindi or English, not both stacked)
- Shimmer skeleton on load, soft festive glow behind the header

### Festivals ("सभी त्योहार")
- Religion filter chips (सभी/हिंदू/मुस्लिम/सिख/ईसाई/जैन/बौद्ध/राष्ट्रीय)
- List of 21 festivals — image, name, date, "X दिन बाकी" countdown, chevron
- Floating **+** button → Customize screen
- Shimmer skeleton on load

### Status Gallery (per-festival or general)
- Reached from a festival tap, a category tile, or the carousel
- Tabs: सभी / नए / लोकप्रिय / प्रीमियम (Premium tab actually filters to non-free items; लोकप्रिय actually sorts by like count — these are real, not decorative)
- Grid cards with **USE** (green, jumps straight to Preview & Share) and **CUSTOMIZE** (orange, opens the Customize screen) buttons, like button, FREE/PREMIUM badge

### Customize
- Live preview (real festival photo as default background, or pick from 3 gradient alternatives)
- Name field, photo-add button (UI only — no real image picker wired up yet), optional message field, font-style picker (UI only, doesn't actually change the rendered font yet)
- "Preview देखें" → Preview & Share

### Preview & Share
- Final composed preview, WhatsApp share button, Download + "और विकल्प" buttons (share/download are demo toasts — no real file export or WhatsApp deep link yet)

### Create Post ("अपना स्टेटस बनाएं")
- Text composer with 500-char counter, category picker, media-add row (Photo/Video, GIF, Audio — all currently demo toasts, no real picker), visibility toggle (functional local state)
- Posting just shows a confirmation toast and pops back (nothing is actually added to the Feed — Feed is separate static mock data)

### Feed ("फीड")
- Post cards: avatar, name, timestamp, photo+quote, like/comment/share/save, comment previews
- "..." menu on each post opens a real bottom sheet (save / report)
- Comment button and search icon are still demo toasts

### Saved → "मेरी क्रिएशन्स" (My Creations)
- Tabs: डाउनलोडेड / कस्टमाइज़्ड / फेवरेट — favorite toggle is real (local state), tapping a card opens Preview & Share
- Empty state when a tab has nothing

### Profile
- Orange gradient header, avatar, stats, menu (posts/saved/likes items route into My Creations; "खोजे गए लोग" is a demo toast), settings gear
- Logout shows a toast (no real auth to log out of)

### Settings
- Account/Privacy/Notifications/Help — demo toasts (all inherently need a backend to be real)
- **भाषा (Language)** — real, working. Toggling Hindi/English live-updates category labels on Home via `AppLanguageController`
- थीम (Theme) — picker UI works and remembers the selection, but doesn't actually re-theme the app yet (only one visual theme exists)
- "ऐप के बारे में" opens a real `AboutDialog`

### Side drawer (opened from Home's hamburger)
होम / त्योहार / मेरी क्रिएशन्स / प्रोफाइल / फ़ीड / सेटिंग — all real navigation. "ऐप शेयर करें" triggers the actual native share sheet via `share_plus`.

---

## Data model (all mock, in `lib/data/mock_data.dart`)

- **21 festivals** — Ganesh Chaturthi, Diwali, Dhanteras, Navratri, Krishna Janmashtami, Dussehra, Karva Chauth, Bhai Dooj, Makar Sankranti, Maha Shivratri, Holi, Raksha Bandhan, Republic Day, Independence Day, Eid, Bakrid, Gurpurab, Christmas, Good Friday, Mahavir Jayanti, Buddha Purnima — each with a real image (`assets/festival_icons/`)
- **35 categories** — Motivation, Good Morning/Night, Love, Family, Birthday, Anniversary, National, Religious, Spiritual, Quotes, Thoughts, Positive Vibes, Success, Achievement, Strong Mind, Meditation, World, Kindness, Support, Friendship, Education, Home & Life, Baby & Kids, Flowers, Gifts, Celebration, Memories, Travel, Good Day, Rainy Day, Seasons, Festivals, Events, Party — each with a real icon (`assets/categories_icons/`)
- A handful of mock feed posts, status items, and a "today's quote"

---

## Known gaps (honest list — things that look done but aren't wired to anything real)

- **No backend at all.** Every "post," "like," "save," "comment" only lives in local widget state and resets on app restart.
- **No accounts / login / auth.** The onboarding "login" link and Profile's user info (name "अभिषेक गोयल") are static.
- **No real photo picker** for Customize or Create Post's media row — buttons exist, nothing attaches.
- **No real download/share-to-file** — WhatsApp/download buttons show a confirmation toast, don't actually generate or export an image.
- **No push notifications** — the bell icon is decorative, Settings' notification toggle doesn't request any real permission.
- **Theme picker doesn't re-theme** — only one visual theme is implemented.
- **Search icons** (Feed, Status Gallery, Category page) don't filter anything yet — decorative for now.
- A few Settings/Profile items (Account, Privacy, Notifications, Help, "खोजे गए लोग") are placeholder toasts since they're inherently backend-gated.

## Known-solid (things that are genuinely functional, not just UI)

- Full navigation graph (every screen reachable, no dead links)
- Side drawer, language switch, favorite/like toggles, religion/status filtering and sorting, promo carousel, native share sheet, About dialog, theme selection persistence (visually inert but the choice sticks in state)
- Release signing configured (`android/keystore/har_din_upload.jks` + `android/key.properties`, both gitignored) — app builds a properly signed `.aab` for Play Store upload
- App icon generated from the real logo; Play Store listing text drafted in `store_listing.md`; privacy policy hosted at `vocadose.com/har-din/privacy`

---

## Where things live

```
lib/
  data/mock_data.dart       — all mock content (festivals, categories, posts, quotes)
  models/                   — plain data classes (Festival, HomeCategory, StatusItem, FeedPost, PromoBanner, Category)
  screens/                  — one file per screen
  theme/                    — colors, spacing, text styles, icon set, language controller
  widgets/                  — shared UI pieces (cards, buttons, shimmer, glass effect, drawer)
assets/
  categories_icons/         — 35 flat category icons
  festival_icons/           — 21 festival images
  banners/                  — 4 promo carousel images
  fonts/                    — Poppins + Baloo 2
```
