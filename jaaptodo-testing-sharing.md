Next Steps: Your Testing Plan

Phase 1: Fresh Start Test

1. Run the app on your iPhone
2. Go to Settings → Debug → Reset All Data
3. Restart the app
4. Complete onboarding (create profile)
5. Log a few test events  


Phase 2: Test Sharing

1. In Settings → Sharing → Share with Partner
2. Send the link to your wife
3. She taps link, accepts share
4. Verify her status shows "Accepted" (not "Invited")
5. Log an event on your phone → should appear on hers
6. She logs an event → should appear on yours  


Phase 3: Import Historical Data

Once sharing works:

1. Settings → Debug → Import from Web App
2. This reads from /Users/jstronks/Github NW/Ollie/data/
3. All events will sync to CloudKit automatically
