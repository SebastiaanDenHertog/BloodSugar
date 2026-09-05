# BloodSugar

BloodSugar is a Garmin Connect IQ watch app for manually logging glucose
readings and viewing recent glucose history. It supports mmol/L and mg/dL,
configurable glucose zones, notifications, and Abbott FreeStyle, Dexcom Share,
and xDrip+ integrations.

## Requirements

- Connect IQ API level 3.0.0 or newer.
- A Garmin watch included in `manifest.xml`.

API level 3.0.0 is required because glucose history is stored as a packed
`ByteArray`. This format uses substantially less persistent storage and runtime
memory than keeping every reading as a nested array or dictionary.

## Dexcom Share sign-in

The Dexcom integration ports the request flow used by
[`pydexcom`](https://github.com/gagebenne/pydexcom) to Monkey C. It uses the
unofficial Dexcom Share service to retrieve near-real-time glucose readings.

1. Enable Share in the Dexcom G6/G7 mobile app and configure at least one
   follower.
2. On the watch, select Dexcom and enter the username and password of the
   Dexcom account publishing the readings, not a follower account.
3. Choose the account region: United States, Japan, or Everywhere else.
4. Select Connect. The app authenticates the account, creates a Share session,
   and downloads up to six readings from the last 30 minutes.

The selected region determines which Dexcom Share service is used. The account
ID, region, and Share session are stored under the provider-specific API storage
keys, and an expired session is renewed automatically.

Dexcom Share is unofficial and can change without notice. Credentials are
stored on the watch for background synchronization; consider a trusted backend
instead if that storage model is not acceptable for the intended release.

## xDrip+ connection

The xDrip+ integration reads glucose values from the local xDrip web service at
`http://127.0.0.1:17580/sgv.json`. Select xDrip+ during monitor setup and choose
Connect. No username or password is required.

## Memory efficiency

- Glucose history is packed into a compact `ByteArray`.
- API credentials and sessions are isolated in `BloodSugarApiStore`, while the
  packed codec and small history reader/writer are shared without loading the
  foreground `BloodSugarStore` or full `BloodSugarReading` model.
- History retains five-minute readings for 7 days, hourly averages through day
  30, and six-hour averages through day 180.
- The history is capped at 3,200 packed points (about 21.9 KiB at full capacity),
  leaving space below Garmin's 32 KB per-value storage limit.
- Watches with 128 KiB or less app memory, including the Forerunner 55, use a
  smaller profile: three days at full resolution, two-hour averages through day
  30, and twelve-hour averages after that, capped at 1,500 packed points. The
  profile is based on available app memory rather than screen dimensions.
- The history list loads only the rows currently visible on screen.
- The glance reads packed history values directly instead of creating temporary
  reading arrays.
- Keyboard key and width tables are shared instead of recreated during each
  draw or tap.
- All supported button-only watches exclude the touchscreen keyboard at build
  time; credential entry uses the character picker. This saves program memory
  on constrained devices such as the 96 KiB Descent G1 and Instinct Crossover.
  Keep the target exclusions in `monkey.jungle` aligned with Garmin device
  profiles when adding watches; touchscreen models retain the keyboard.
- Settings reuse one state object and one glucose-zone buffer.
- Text fitting avoids temporary font arrays and uses a binary search when text
  must be shortened.

## Change log

### v0.9.7

- Added Fenix 9 support.
- Added Dexcom Share sign-in with United States, Japan, and everywhere-else
  regions, reusable sessions, and background glucose synchronization.
- Added credential-free xDrip+ setup and glucose synchronization through the
  local xDrip web service.
- Split API, settings, and packed-history storage into smaller shared modules
  for foreground, background, and glance use.
- Improved the connection screen with clear HTTP and network errors, an
  explicit connected state, and a short delay before opening history or home.
- Improved credential entry and display for long usernames and passwords.

### v0.9.63

- Added Garmin button hints to custom screens on non-touch watches.
- Moved the main menu, settings, and setup choices to Garmin native controls,
  including native toggle switches for boolean settings.
- Checked and corrected layouts across the supported watch families.

### v0.9.62

- Keyboard is visible.
- The selected item for entering a username or password is shown more clearly.

### v0.9.61

- Added a button-controlled keyboard for non-touch watches, while keeping the
  QWERTY keyboard on touchscreen watches.
- Added a smaller history profile for watches with limited app memory.
- Improved history navigation and reduced memory use when opening the history
  list repeatedly.
- Made graph limits clearer: danger-low and danger-high are red, while the
  warning limits are orange with matching labels.
- Improved monitor setup and sync cancellation reliability.
- Abbott FreeStyle integration remains in beta until v1.0.0.

### v0.9.6

- Reduced temporary allocations in the keyboard, glance, history list,
  settings, and text-rendering paths.
- Added compact packed history storage.
- Added automatic six-month history retention with age-based averaging.
- Raised the minimum Connect IQ API level to 3.0.0 for `ByteArray` support.

### v0.9.5

- Divided settings into categories and added a green saved-state indicator.
- Moved page layouts into size-family resources.

### v0.9.4

- Added an on-watch keyboard as an alternative input method.

### v0.9.3

- Added a new settings interface.

### v0.9.2

- Added Abbott FreeStyle monitor integration.
- Added low- and high-glucose notifications.

### v0.9.1

- Added the initial graph, list view, and manual glucose input.
- Added support for mmol/L and mg/dL.

## Reference

The Abbott FreeStyle connection is based on the
[`DiaKEM Libre API client`](https://github.com/DiaKEM/libre-link-up-api-client).

The Dexcom connection is based on
[`pydexcom`](https://github.com/gagebenne/pydexcom).

Custom button screens use Garmin's
[Personality UI input hints](https://developer.garmin.com/connect-iq/personality-library/input-hints/),
while menus and setup choices use Garmin's
[native controls](https://developer.garmin.com/connect-iq/core-topics/native-controls/).
Boolean settings use Garmin's
[ToggleMenuItem](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/ToggleMenuItem.html).

## Development

Monkey C files are formatted with
[Prettier Monkey C](https://marketplace.visualstudio.com/items?itemName=markw65.prettier-extension-monkeyc)
(`markw65.prettier-extension-monkeyc`).

## License

This project is licensed under the MIT License. See [LICENSE.txt](LICENSE.txt).
