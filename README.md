# BloodSugar

BloodSugar is a Garmin Connect IQ watch app for manually logging glucose
readings and viewing recent glucose history. It supports mmol/L and mg/dL,
configurable glucose zones, notifications, and Abbott FreeStyle integration.

## Requirements

- Connect IQ API level 3.0.0 or newer.
- A Garmin watch included in `manifest.xml`.

API level 3.0.0 is required because glucose history is stored as a packed
`ByteArray`. This format uses substantially less persistent storage and runtime
memory than keeping every reading as a nested array or dictionary.

## Dexcom sign-in (developer testing)

The Dexcom integration uses OAuth 2.0 through Garmin Connect Mobile. To test
it:

1. Create an app in the Dexcom developer portal and register
   `http://localhost` as its redirect URI. The value must match exactly.
2. In `source/api/Dexcom/Dexcom_Api.mc`, select the appropriate
   `DEFAULT_SERVER`. It currently uses the EU/outside-US production server;
   use `SANDBOX_SERVER` for Dexcom's simulated users.
3. On the watch, select Dexcom and enter the developer app's client ID and
   client secret. These are app credentials, not a Dexcom user's email and
   password.
4. Select Connect, open the Garmin Connect notification on the paired phone,
   sign in to Dexcom, and approve access.

The app validates the OAuth state, exchanges the one-minute authorization
code, saves the access and refresh tokens, rotates the refresh token when
needed, locates the newest available EGV using Dexcom's data-range endpoint,
and loads the 15 minutes of readings leading up to it.

This direct token exchange is suitable only for local/sandbox development.
Dexcom requires production integrations to keep client secrets and user tokens
on a server rather than distributing or storing them on a mobile or wearable
client. A production release should proxy the code exchange, token refresh,
and Dexcom data calls through an application backend.

## Memory efficiency

- Glucose history is packed into a compact `ByteArray`.
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
- Settings reuse one state object and one glucose-zone buffer.
- Text fitting avoids temporary font arrays and uses a binary search when text
  must be shortened.

## Change log

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
[DiaKEM Libre API client](https://github.com/DiaKEM/libre-link-up-api-client).
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
