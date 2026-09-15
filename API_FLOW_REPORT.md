# हर दिन — App Flow और API Call रिपोर्ट

Base URL: `https://api-hardin.vocadose.com`
Endpoints इस्तेमाल हुए: `/v1/version`, `/v1/content`, `/v1/events`

यह रिपोर्ट पूरी तरह code trace पर आधारित है (runtime logs नहीं) — हर claim नीचे दी गई files से verify किया गया है।

---

## 1. Step-by-step Flow (Splash से Home तक)

### Step 1 — SplashScreen
2 सेकंड का timer, फिर सीधे OnboardingScreen पर navigate।
**API calls: कोई नहीं**

### Step 2 — OnboardingScreen
"शुरू करें" टैप करने पर `LocalStore.getLanguage()` चेक होता है (सिर्फ local prefs)।
- भाषा पहले से saved है → सीधे RootShell
- नहीं है → LanguageSelectScreen

**API calls: कोई नहीं (सिर्फ local read)**

### Step 3 — LanguageSelectScreen (सिर्फ पहली बार)
खुलते ही भाषा options दिखाने के लिए एक "bootstrap" fetch चलता है (कोई अलग languages-list endpoint नहीं है, इसलिए default `hi` से content मंगाकर उसका `languages[]` field पढ़ा जाता है)।

- **CALL 1:** `GET /v1/version?lang=hi`
- **CALL 2:** `GET /v1/content?lang=hi` — पहली बार हमेशा चलती है (कोई stored version नहीं होता)

### Step 4 — LanguageSelectScreen → "आगे बढ़ें"
User कोई भाषा चुनकर आगे बढ़ता है।

- अगर `hi` चुना → कोई extra call नहीं (bootstrap का data reuse होता है)
- अगर `en`/`mr` चुना → `GET /v1/version?lang=<selected>` (हमेशा चलती है)
- ⚠️ `GET /v1/content?lang=<selected>` — सिर्फ तब चलती है जब version नंबर बदला हो (देखें Finding #1)

### Step 5 — RootShell
हर cold start पर एक बार mount होता है (`_loadTriggered` flag से guard, दोबारा नहीं चलता)।

- ज़्यादातर: **कोई कॉल नहीं** — 30-मिनट के throttle की वजह से (अभी-अभी language-select में check हुआ था)
- 30+ मिनट बाद reopen पर: `GET /v1/version?lang=<code>` + शर्त पूरी होने पर content भी
- `app_open` event सिर्फ local queue में लिखा जाता है, तुरंत server को नहीं भेजा जाता

### Step 6 — Tabs (होम · त्योहार · मेरी क्रिएशन्स · प्रोफाइल)
Bottom nav से tab बदलना सिर्फ पहले से loaded payload को पढ़ता है।
**API calls: 0** (tab switch पर content दोबारा नहीं मंगाया जाता — यह सही व्यवहार है)

### Step 7 — Status Gallery / Category Detail / Search
Design grid, time-band filter, search सब local `payload.designs[]` पर चलते हैं। Like/favorite भी सिर्फ local file (`SavedDesignsController`) में जाता है।
**API calls: 0**

### Step 8 — Preview & Share
Design खुलते ही एक `design_view` event local queue में जाता है। Share/Download दबाने पर असली image file चाहिए होती है।

- Image fetch: `GET <display_url>` — यह har-din API का हिस्सा नहीं है, image CDN से आता है; पहली बार fetch होकर हमेशा के लिए cache हो जाती है (filenames immutable हैं)
- `share_complete` / `download_complete` events — दोनों local queue में जाते हैं

### Step 9 — Settings → भाषा बदलना
- `GET /v1/version?lang=<new>` हमेशा चलती है
- ⚠️ `GET /v1/content?lang=<new>` सिर्फ तब चलती है जब version नंबर बदला हो (देखें Finding #1)

---

## 2. पूरा API Call Matrix

| Trigger | Endpoint | शर्त (Condition) | नतीजा |
|---|---|---|---|
| पहला app launch — bootstrap | `GET /v1/version?lang=hi` | हमेशा (forced) | CALL |
| पहला app launch — bootstrap | `GET /v1/content?lang=hi` | storedVersion null (पहली बार हमेशा true) | CALL |
| भाषा चुनकर "आगे बढ़ें" (hi नहीं) | `GET /v1/version?lang=<selected>` | हमेशा (forced) | CALL |
| भाषा चुनकर "आगे बढ़ें" (hi नहीं) | `GET /v1/content?lang=<selected>` | सिर्फ अगर fetched version ≠ storedVersion | ⚠️ BUG रिस्क |
| RootShell mount (हर cold start) | `GET /v1/version?lang=<code>` | सिर्फ अगर lastVersionCheck > 30 मिनट पुराना | ज़्यादातर SKIP |
| RootShell mount (30+ मिनट बाद) | `GET /v1/content?lang=<code>` | सिर्फ अगर version नंबर बदला हो | कभी-कभी CALL |
| Settings → भाषा बदलना | `GET /v1/version?lang=<new>` | हमेशा (forced) | CALL |
| Settings → भाषा बदलना | `GET /v1/content?lang=<new>` | सिर्फ अगर fetched version ≠ storedVersion | ⚠️ BUG रिस्क |
| Home पर "फिर से कोशिश करें" | `GET /v1/version?lang=<code>` | सिर्फ अगर throttle window पार हो चुकी | ⚠️ retry खुद throttle bypass नहीं करता |
| Tab switch (Home/त्योहार/क्रिएशन्स/प्रोफाइल) | — | — | 0 CALLS |
| Design खोलना / Preview / Search | — | local payload/tags पर filter | 0 CALLS |
| Share / Download बटन | `GET <display_url>` | हर unique URL के लिए सिर्फ पहली बार, फिर cache से | image fetch |
| Local event queue | `POST /v1/events` | queue में ≥20 pending events | ⚠️ सिर्फ यही ट्रिगर है |

---

## 3. Duplicate / Double API call — सीधा जवाब

कोई भी endpoint बिना वजह दो बार back-to-back नहीं चलता — हर जगह throttle/guard लगा हुआ है। लेकिन trace करने पर दो जगह ऐसी मिलीं जहाँ code सही तरीके से call *नहीं* चलाता, और वजह गलत है — यह duplicate call से भी बुरा है क्योंकि user को पता भी नहीं चलता।

### Finding #1 — HIGH — Content-version language-specific नहीं है

`storedVersion` पूरे app के लिए एक ही global number है (per-language नहीं)। जब भाषा बदली जाती है, code सिर्फ यह चेक करता है कि नया `version.content` पुराने `storedVersion` से अलग है या नहीं — भाषा अलग है या नहीं, यह नहीं देखता।

**उदाहरण:** User पहली बार हिंदी चुनता है → version 8 आता है, content fetch होता है, `storedVersion=8` save होता है। फिर English पर switch करता है → server से version अभी भी 8 आता है (क्योंकि version पूरे content-deployment का है, भाषा का नहीं) → code सोचता है "कुछ नया नहीं है" और `GET /v1/content?lang=en` कभी नहीं चलाता। UI पर अब भी हिंदी वाला payload दिखता रहता है, सिर्फ label "English" हो जाता है।

फ़ाइल: `lib/data/repositories/content_repository_impl.dart` → `_checkVersionAndMaybeFetch()`

### Finding #2 — MEDIUM — Analytics events कभी server तक पहुंचते ही नहीं (ज़्यादातर सेशन में)

`EventQueue.flush()` — जो असल में `POST /v1/events` चलाता है — सिर्फ तब call होता है जब local queue में 20 या ज़्यादा events जमा हो जाएं। App background में जाने पर, या अगली बार app खुलने पर — दोनों में से कोई भी flush को trigger नहीं करता (कोड में कहीं भी app-lifecycle listener नहीं है)।

**उदाहरण:** एक normal session में user 3 designs देखता है और 1 बार share करता है — यानी सिर्फ ~5 events बनते हैं। App बंद करते ही ये 5 events local file में पड़े रह जाते हैं, अगले कई sessions तक, जब तक cumulative count 20 पार न कर जाए। चूंकि `share_complete`/`download_complete` ही v1 का सबसे ज़रूरी metric है, यह admin panel के stats को लंबे समय तक कम दिखा सकता है।

फ़ाइल: `lib/core/services/event_queue.dart` → `flush()` कहीं और से call नहीं होता

---

## Verify की गई Files

- `lib/data/repositories/content_repository_impl.dart`
- `lib/core/services/event_queue.dart`
- `lib/screens/root_shell.dart`
- `lib/screens/language_select_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/preview_share_screen.dart`
- `lib/core/services/share_service.dart`
