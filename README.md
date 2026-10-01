# Blue Main iOS v0.2

CallKit incoming-call diagnostic prototype for the Blue Main project.

## v0.2 changes
- Added `UIBackgroundModes` with `voip` for CallKit/VoIP background support.
- Added detailed CallKit error domain/code/userInfo logging.
- Added explicit incoming-call error classification.
- Logs audio-session sample rate and channel counts when CallKit activates the audio session.
- BLE, GSM and HFP are intentionally not included yet.

## Test
1. Install the v0.2 build on the iPhone.
2. Open **J7Bridge**.
3. Tap **TEST INCOMING CALL**.
4. If the CallKit UI appears, answer it and observe the status/logs.
5. If it fails, capture the exact `domain=... code=... userInfo=...` line.

The current goal is to isolate the CallKit layer before adding the BLE/GATT control and audio layers.
