# CloudKit Setup Guide

Your app is configured to use CloudKit but the container needs to be created in the Apple Developer Portal. Follow these steps to complete the setup.

## Current Configuration

| Setting      | Value                         |
| ------------ | ----------------------------- |
| Bundle ID    | `jaapstronks.Ollie-app`       |
| Team ID      | `ZA6R83F354`                  |
| Container ID | `iCloud.nl.jaapstronks.Ollie` |

---

## Step 1: Wait for Apple Developer Program Activation

After paying the €99, it can take **up to 48 hours** for your membership to be fully activated. You'll receive an email from Apple when it's ready.

To check your status:

1. Go to [developer.apple.com](https://develo per.apple.com)
2. Sign in with your Apple ID
3. Click "Account" in the top menu
4. Look for "Membership" - it should show "Apple Developer Program"

**If you see "Pending" or get access errors, wait for the activation email.**

---

## Step 2: Create the iCloud Container

Once your membership is active:

1. Go to [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers)

2. In the left sidebar, click **"Identifiers"**

3. Click the **"+"** button (top left, next to "Identifiers")

4. Select **"iCloud Containers"** and click **Continue**

5. Enter the container ID exactly as shown:

   ```
   iCloud.nl.jaapstronks.Ollie
   ```

   (The "iCloud." prefix is added automatically, so you may only need to enter `nl.jaapstronks.Ollie`)

6. Click **Continue**, then **Register**

---

## Step 3: Configure the App ID

1. Still in [Identifiers](https://developer.apple.com/account/resources/identifiers), find your App ID:
   - Look for `jaapstronks.Ollie-app`
   - If it doesn't exist, you'll need to create it (click "+", select "App IDs", type "App")

2. Click on your App ID to edit it

3. Scroll down to **Capabilities** and enable:
   - [x] **iCloud** - Check this box
   - Click **Configure** next to iCloud
   - Select **"Include CloudKit support"**
   - Under "iCloud Containers", check `iCloud.nl.jaapstronks.Ollie`
   - Click **Save**

4. Also enable:
   - [x] **Push Notifications** (required for CloudKit sync)

5. Click **Save** at the top

---

## Step 4: Regenerate Provisioning Profiles

After changing capabilities, you need new provisioning profiles:

1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)

2. Find profiles for `jaapstronks.Ollie-app`

3. Either:
   - **Delete them** and let Xcode create new ones automatically, OR
   - **Edit each one** and click "Generate" to update them

---

## Step 5: Configure Xcode

1. Open `Ollie-app.xcodeproj` in Xcode

2. Select the **Ollie-app** target (click on the project in the navigator, then select the target)

3. Go to the **"Signing & Capabilities"** tab

4. Ensure:
   - Team is set to your account (should show your name)
   - "Automatically manage signing" is checked
   - No red error icons appear

5. If you don't see iCloud capability listed:
   - Click **"+ Capability"** button (top left of the capabilities section)
   - Search for **"iCloud"**
   - Double-click to add it

6. Configure the iCloud capability:
   - Check **"CloudKit"**
   - Under "Containers", click the **"+"** button
   - Add: `iCloud.nl.jaapstronks.Ollie`
   - Make sure it's checked

7. If you see a **"Push Notifications"** capability, ensure it's there. If not, add it too.

---

## Step 6: Initialize the CloudKit Schema (First Run)

The first time you run the app with CloudKit working:

1. Run on a **real device** (CloudKit works better on device than simulator)

2. Make sure you're signed into iCloud on the device:
   - Settings > [Your Name] > iCloud
   - Ensure iCloud Drive is enabled

3. Open the CloudKit Dashboard to verify:
   - Go to [icloud.developer.apple.com/dashboard](https://icloud.developer.apple.com/dashboard)
   - Select your container `iCloud.nl.jaapstronks.Ollie`
   - You should see record types appear after the app runs

---

## Troubleshooting

### "Signing certificate not found" error

- Go to Xcode > Settings > Accounts
- Select your Apple ID, click "Manage Certificates"
- Click "+" and create a new "Apple Development" certificate

### "Container doesn't exist" error

- Double-check the container ID matches exactly: `iCloud.nl.jaapstronks.Ollie`
- Wait a few minutes after creating the container - it takes time to propagate

### "No iCloud account" error on device

- Ensure you're signed into iCloud on the test device
- Check that iCloud Drive is enabled in Settings

### App crashes on simulator

- This is expected if entitlements aren't set up yet
- The code has guards to skip CloudKit on simulator, but they may not work until the container exists
- **Test on a real device first**

### Capability not showing in Xcode

- Make sure your Apple Developer membership is fully activated
- Try: Xcode > Settings > Accounts > Select your account > "Download Manual Profiles"
- Restart Xcode

---

## Files Reference

These files are already configured in your project:

| File                                       | Purpose                               |
| ------------------------------------------ | ------------------------------------- |
| `Ollie-app/Ollie-app.entitlements`         | Declares iCloud/CloudKit entitlements |
| `Ollie-app/Services/CloudKitService.swift` | CloudKit sync implementation          |
| `Ollie-app/Services/EventStore.swift`      | Uses CloudKit for event sync          |

---

## After Setup

Once CloudKit is working:

1. Delete this file (`TODO-cloudkit-setup.md`)
2. The app will sync events across devices automatically
3. Check the CloudKit Dashboard to see your data

---

**Questions?** Check [Apple's CloudKit documentation](https://developer.apple.com/documentation/cloudkit) or the WWDC videos on CloudKit.
