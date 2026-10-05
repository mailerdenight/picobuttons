# ピコボタン / Pico Buttons — App Store metadata v1

## Positioning

Free retro sound toy with low-interruption banner ads and carefully limited interstitials. Pico Buttons Pro is a one-time purchase that removes ads.

## Japanese promotional text

28種類のオリジナル電子音を、4列×7行のボタンですぐ鳴らせます。Pico Buttons Proなら広告なしで楽しめます。

## English promotional text

Play 28 original retro electronic sounds on a four-by-seven button board. Pico Buttons Pro is a one-time purchase that removes ads.

## Required submission updates

- Do not claim that the app is offline-only, ad-free, tracking-free, or data-not-collected.
- `SettingsView` now uses `https://mailerdenight.github.io/pico-buttons-privacy/`. Verify the published policy and register the same URL in App Store Connect before review.
- In App Store Connect, declare data collection based on the final AdMob/UMP SDK configuration and current vendor documentation.
- Production AdMob app, banner, and interstitial IDs are configured in the code. Verify their ownership and serving configuration in AdMob and on a device before release.
- Create the non-consumable `com.ac.picobuttons.pro` product in App Store Connect, configure its price, and submit it with the app.
