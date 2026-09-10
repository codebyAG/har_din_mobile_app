# Har Din — App Integration Guide (v1)

> For the Flutter app developer. This is the working document; the machine-readable
> contract lives at **https://api-hardin.vocadose.com/docs** and is generated
> from the same schemas that validate every real request, so it cannot go stale.
> Read it there rather than from a copy anyone emailed you.

---

## 1. What v1 is, and is not

v1 is a **content delivery and sharing test**. Admins upload finished designs;
the app shows them; the user shares one to WhatsApp. That is the whole loop.

**The loop:** Open → Choose → Share.

**No editing in v1.** Name, photo, message, fonts, colours — all of that is v2.
Designs are shown exactly as uploaded, as static images.

**No accounts, no user content, no payments.** There is no login, no feed, no
posting, no premium tier, and no push notifications. Nothing in the backend
supports them, deliberately.

**What v1 measures:** `shares ÷ views`. That single number decides what gets
built next, which makes the share path the most important code in the app — see
§2.

---

## 2. Start here: the share path is priority one

Right now Download and WhatsApp share are demo toasts. In v1 they are the *only*
thing being measured, so they have to actually work:

1. Download `display_url` for the chosen design (cache it — see §6).
2. Hand that file to the platform share sheet, and to a WhatsApp intent for the
   WhatsApp button.
3. For Download, save it to the gallery.
4. Fire a `share_complete` or `download_complete` event — **after** the share
   sheet is invoked, never blocking it (§8).

No compositing, no overlay, no watermark in v1. The file you share is the file
you downloaded.

> A watermark is required before any public launch — it is the product's only
> free distribution channel — but it is deliberately out of the test build.

---

## 3. The API: three endpoints, and no others

Base URL (staging): `https://api-hardin.vocadose.com`

Languages available: `hi`, `en`, `mr`.

| Endpoint | When you call it |
|---|---|
| `GET /v1/version?lang=hi` | Every app open, throttled to once per 30 minutes |
| `GET /v1/content?lang=hi` | **Only** when the version number changed |
| `POST /v1/events` | Batched, in the background, fire and forget |

There is no search endpoint, no pagination, no per-category endpoint, and no
auth. If you find yourself wanting one, re-read §5 — the data is already on the
device.

**Never fetch `/openapi.json` or `/docs` from the app.** Those are for you, at
build time.

### `GET /v1/version?lang=hi`

```json
{ "content": 148 }
```

A few bytes, edge-cached. It is an object rather than a bare number so that
per-section versions can be added later without breaking installed builds —
so read `body["content"]`, and ignore any other keys you find.

### `GET /v1/content?lang=hi`

The app's entire database in one response. About 200KB of text for a launch-size
library, ~24KB gzipped — smaller than one thumbnail.

```json
{
  "version": 148,
  "languages": [
    { "code": "hi", "label": "हिन्दी" },
    { "code": "en", "label": "English" },
    { "code": "mr", "label": "मराठी" }
  ],
  "time_bands": {
    "morning":   [4, 11],
    "afternoon": [11, 16],
    "evening":   [16, 20],
    "night":     [20, 4]
  },
  "home": {
    "carousel_category_id": "…",
    "category_order": ["…", "…"],
    "time_band_categories": { "morning": ["…"], "night": ["…"] }
  },
  "banners": [
    { "id": "…", "image_url": "…", "target": "category",
      "target_ref": "…", "sort_order": 0 }
  ],
  "categories": [
    { "id": "…", "parent_id": null, "name": "सुप्रभात",
      "icon_url": "…", "cover_url": null, "layout": "grid", "sort_order": 0 }
  ],
  "tags": [
    { "id": "…", "name": "सुप्रभात",
      "terms": ["good morning", "सुप्रभात", "शुभ सकाळ", "gm", "subh prabhat"] }
  ],
  "designs": [
    {
      "id": "…",
      "category_id": "…",
      "media_type": "image",
      "scope": "language",
      "thumbnail_url": "…",
      "display_url": "…",
      "original_url": "…",
      "width": 1080,
      "height": 1920,
      "time_band": "always",
      "tag_ids": ["…"],
      "slots": {},
      "sort_order": 0,
      "published_at": "2026-09-08T07:07:00.000Z",
      "stats": { "views": 0, "shares": 0, "downloads": 0 }
    }
  ],
  "occasions": [
    { "id": "…", "name": "क्रिसमस", "date": "2026-12-25",
      "category_id": "…", "community": "christian", "image_url": null }
  ]
}
```

### `POST /v1/events`

```json
{
  "device_id": "…",
  "events": [
    { "id": "<client-uuid>", "design_id": "…", "type": "share_complete",
      "at": "2026-09-08T04:12:00Z" }
  ]
}
```

Returns `204` with no body. See §8.

---

## 4. The caching contract

This is the design the whole backend exists to serve. Get this right and repeat
opens cost nothing.

```
on app open:
  if (now - lastVersionCheck) < 30 minutes:
      render from local storage, stop
  v = GET /v1/version?lang=<selected>
  if v.content == storedVersion:
      render from local storage, stop        ← the common case
  payload = GET /v1/content?lang=<selected>
  replace local copy, store payload.version
  render
  download only image URLs not already cached
```

**Store locally:** the whole payload (Hive, Isar, sqflite or a JSON file — your
call), plus `storedVersion` and `lastVersionCheck`.

**Never** call `/v1/content` on a screen change, a pull-to-refresh of a
category, or a tab switch. Only a changed version number justifies it.

**Bundle 10–15 designs in the APK** so a first open with no signal is not blank.

**Everything already downloaded must work with no connection**, indefinitely.

---

## 5. Screens and how they read the payload

Nothing here needs a network call. Every screen is a query against the stored
payload.

| Screen | v1 status | Reads |
|---|---|---|
| Splash / Onboarding | keep | — |
| **Language select** | **new — required** | `languages[]`, in each label's own script. Store the choice; it becomes `?lang=` forever |
| Home — banners | keep | `banners[]`, ordered by `sort_order`, `target`/`target_ref` for the tap. **Empty until banners are uploaded** — keep the bundled ones as a fallback |
| Home — categories grid | keep | `categories[]` where `parent_id == null`, ordered by `home.category_order`, else `sort_order`. Labels come from `name`, already in the selected language. `icon_url` may be null — fall back to your bundled icon, then to a generic one |
| Home — today's occasion | **new** | `occasions[]` where `date == today` → open `category_id` |
| Home — upcoming | **new** | next few `occasions[]` by `date`, with a day countdown |
| Home — time-of-day row | **new** | `home.time_band_categories[currentBand]` (§7) |
| Festivals list | keep | `occasions[]`. Religion chips filter on `community` (`hindu`, `muslim`, `sikh`, `christian`, `jain`, `buddhist`, `national`, `other`). Image is `image_url` |
| Status Gallery grid | keep | `designs[]` filtered by `category_id` |
| — tab सभी | keep | all of them |
| — tab नए | keep | sort by `published_at` desc |
| — tab लोकप्रिय | keep | sort by `stats.shares` desc |
| — tab प्रीमियम | **comment out** | no paywall exists in v1 |
| — FREE/PREMIUM badge | **comment out** | same |
| — `USE` button | keep, make full width | opens Preview & Share |
| — `CUSTOMIZE` button | **disable, "Coming soon"** | v2 |
| — like button | keep | local only. Never sent to the server |
| Search (all screens) | **enable — it now works** | filter stored `designs[]` by `tags[].terms` (§9) |
| Customize screen | **disable, "Coming soon"** | v2 — keep the code, don't route to it |
| Festivals floating `+` | **disable, "Coming soon"** | it opened Customize |
| Preview & Share | keep — **must become real** | `display_url` (§2) |
| My Creations — डाउनलोडेड | keep | local storage |
| My Creations — फेवरेट | keep | local storage |
| My Creations — कस्टमाइज़्ड | **empty state, "Coming soon"** | nothing to put in it yet |
| Create Post (centre nav) | **comment out** | no upload endpoint, no accounts, no moderation |
| Feed | **comment out** | no posts, no comments, no users |
| Profile — stats, खोजे गए लोग, logout | **comment out** | no accounts |
| Onboarding "login" link | **comment out** | no auth |
| Notification bell | **comment out** | push is post-v1 |
| Settings — भाषा | keep, wire to API | `languages[]` |
| Settings — theme, about | keep | client-side |
| Settings — account/privacy/notifications/help | **comment out or link out** | backend-gated |

Bottom nav drops to four: **होम · त्योहार · मेरी क्रिएशन्स · प्रोफाइल**.

**Keep the code for everything marked "comment out".** It comes back in v2/v3 —
just make it unreachable so nothing in v1 leads to a dead end.

---

## 6. Images and media caching

**Three URLs per design, three different jobs:**

| URL | Size | Use it for |
|---|---|---|
| `thumbnail_url` | ~20–40KB, 300px | Every grid, list and carousel tile |
| `display_url` | ~110–150KB, 1080px | The viewer, and the file you share |
| `original_url` | multi-MB | **Never.** It exists as the server's archive |

**Rules:**

- Load `thumbnail_url` for anything in a grid. Loading `display_url` into a grid
  wastes roughly 5× the bandwidth for no visible gain.
- Fetch `display_url` lazily, when a design is opened.
- **Cache both forever.** Filenames are immutable — a replaced design is written
  under a new name, never overwritten — so a URL always points to identical
  bytes. `CachedNetworkImage` or `flutter_cache_manager` with a long TTL is
  fine; there is no invalidation to handle.
- **Cache ceiling 200–300MB, LRU.** Evict `display_url` files first, keep
  thumbnails longest — a soft grid is far more visible than one slow viewer open.
- **Prefetch tomorrow's occasion carousel overnight on WiFi only.** Never on
  mobile data.
- Offer **Clear cache** in Settings.

**On `media_type` and video:** every design carries `media_type`, and v1 only
ever sends `"image"`. Video may be added server-side later.

```dart
// Skip what this build cannot render. Do not assume, do not crash.
final renderable = designs.where((d) => d.mediaType == 'image');
```

Write that filter now. It costs one line and it means a future video row is
ignored by builds already on people's phones — which matters, because a large
share of users never update apps. When video does arrive it brings a poster
frame, a duration, and its own cache policy; none of that is your problem yet.

---

## 7. Four rules that fail silently

None of these throw. They just quietly show the wrong thing, so they are worth
getting right the first time.

### `always` is not a clock band

The server never filters by time — it ships the labels and the boundaries, and
the device reads its own clock. `always` means evergreen.

```dart
// WRONG — every evergreen design disappears
if (design.timeBand == currentBand) show(design);

// RIGHT
if (design.timeBand == 'always' || design.timeBand == currentBand) show(design);
```

### The night band wraps midnight

Bands are `[start, endExclusive]` in local time, and night is `[20, 4]`.

```dart
// WRONG — matches nothing, for eight hours a day
if (hour >= 20 && hour < 4) band = 'night';

// RIGHT
if (hour >= 20 || hour < 4) band = 'night';
```

### `global` scope ignores language entirely

A design with `scope: "global"` has no language-specific text — frames, rangoli
borders, photo templates — so the server already put it in every language's
payload. Its own `language` field is not in the payload at all, and you must not
filter on scope.

Show every design the payload gives you. The server has already scoped it.

### Unknown `media_type` must be skipped, not assumed

See §6.

### Refresh on a band boundary

When the app returns to the foreground, recompute the current band. Good morning
should quietly become good night without a fetch.

---

## 8. Analytics

Five event types:

`app_open` · `design_view` · `personalize_complete` · `share_complete` ·
`download_complete`

`personalize_complete` simply never fires in v1. Leave it in the enum.

**Never call the server when an event happens.** Write it to a local queue:

```
{ id: <uuid v4, generated on device>, design_id: <or null for app_open>,
  type: 'share_complete', at: <device ISO timestamp with offset> }
```

**Flush** on whichever comes first:
- the queue reaches ~20 events
- the app moves to background
- the next app open

A session with forty views and two shares should produce **one** request, not
forty-two.

**Rules:**

- `id` must be **client-generated and unique**. The server dedupes on it, so a
  retried batch cannot double-count. Keep the same id across retries.
- `at` is the **device clock**, not send time. Batches arriving hours late are
  expected and handled.
- **Fire and forget.** A failure or timeout must never show an error, block a
  share, or delay a screen. Keep the queue and retry on the next flush.
- Offline events accumulate and go out when connectivity returns.
- Send at most 200 events per request.
- Recording an event **never** touches the cache — no version comparison, no
  content refetch, no image re-download. A user who shares fifty designs has
  exactly the same cached content afterwards.

Generate the `device_id` once on first launch and store it. It is a random
identifier for batching and rate limiting — not an account, and not tied to
anything personal.

---

## 9. On-device search

There is no search endpoint, deliberately. Filter the stored payload:

```dart
final q = query.trim().toLowerCase();
final matchedTagIds = tags
    .where((t) => t.terms.any((term) => term.contains(q)))
    .map((t) => t.id)
    .toSet();

final results = designs.where((d) =>
    d.tagIds.any(matchedTagIds.contains));
```

`terms` already contains every language's name plus the aliases, all lowercased
— which is how `deepavali` finds Diwali and `gm` finds good morning. Match
against `terms`, and display `tags[].name`.

Because the device only holds its own language plus global content, search
cannot surface the wrong language. That is the point.

---

## 10. Errors and edge cases

| Situation | What the app does |
|---|---|
| `404` on version/content | The language no longer exists. Fall back to the first entry in the stored `languages[]`, or re-prompt for language choice |
| `429` | Rate limited. Back off, keep the stored copy, try on the next open. Never surface it |
| Timeout / no network on version check | Render from local storage. This is a normal path, not an error |
| Timeout on content fetch | Keep the old payload and the old version number. Do not partially apply |
| Event send fails | Silence. Keep the queue |
| An image 404s | Hide that tile. It means content was replaced; the next version bump fixes it |
| Payload has a field you don't know | Ignore it. Fields get added server-side without app releases |

**Fail toward the cached copy, always.** A stale library is a working app; an
error dialog is not.

---

## 11. Reserved fields — present, unused in v1

Read the contract, don't act on these yet, and don't break on them:

| Field | Status |
|---|---|
| `slots` | Name/photo placement for the v2 editor. Currently `{}` on most designs. Ignore in v1 |
| `media_type` | Always `"image"` in v1. Filter on it anyway (§6) |
| `stats` | Server-aggregated counters, used for the लोकप्रिय sort. Do not display raw numbers to users |
| `original_url` | The server's archive. Never fetch it |
| `banners[].target: "external"` | Not used yet; `target_ref` would be an absolute URL |

---

## 12. Suggested build order

1. Language selection from `languages[]`, stored
2. Content fetch + local persistence + version compare
3. Home: banners, categories, today's occasion, upcoming
4. Category grid from `designs[]`, thumbnails only
5. Viewer + **Preview & Share with real file export** ← the thing v1 measures
6. Image cache with the LRU ceiling
7. Time-band filtering (§7)
8. On-device search
9. Event queue and batched sending
10. Disable/comment the out-of-scope screens (§5)
11. Offline behaviour and the bundled fallback designs

Steps 1–5 give you a testable app. Everything after that makes it good.

---

## 13. Definition of done for v1

- Picking a language on first launch loads real content from the API.
- Opening the app twice in a row makes **one** tiny version call the second
  time and downloads nothing.
- Every category tile and grid renders from thumbnails, not display images.
- Sharing a design to WhatsApp produces a real image file, and a
  `share_complete` event appears in the admin panel's stats within a few
  minutes.
- Turning off the network and reopening the app still shows everything already
  downloaded.
- Searching `deepavali` finds Diwali designs.
- A Marathi device never sees a Hindi-only design.
- No screen in the app leads to a dead end or a demo toast — anything not in v1
  says "coming soon".

---

## 14. Contract, fixture, and changes

- **Contract:** `https://api-hardin.vocadose.com/docs` — read it here.
  `openapi.json` at the same host if you want to generate models.
- **Models:** generate them or hand-write them (it is about eight classes), but
  **commit them in your repo** so builds are reproducible and work offline.
  Never fetch the contract at runtime.
- **Fixture:** save one real response for your tests —
  `curl -s "https://api-hardin.vocadose.com/v1/content?lang=hi" > content_sample.json`
  — and treat it as a test fixture, not as the contract. It will age.
- **Changes:** when the contract changes, you will be told. The URL updating is
  not a notification. Every commit also publishes `openapi.json` as a CI
  artifact, so any two versions can be diffed.
