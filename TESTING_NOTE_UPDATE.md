# Testing Note Update Feature

## Prerequisites
- Device with SMS capability
- Google account signed in
- Drive access granted in app

## Test Steps

### Test 1: Add Note to New Transaction

1. **Trigger SMS transaction**:
   ```
   Send test SMS from JM-KOTAKD-S:
   "Rs 1.00 debited from A/c XX1234 on 28-Apr-26. UPI/123456"
   ```

2. **Check notification appears**:
   - Should show transaction details
   - Should have "Add Note" button

3. **Add note via notification**:
   - Tap "Add Note" button
   - Type note: "Test note 1"
   - Press send/submit

4. **Check Android logs**:
   ```bash
   adb logcat | grep "KharchaBackground"
   ```
   - Should see: "Note submitted for transaction..."
   - Should see: "Updated transaction note in SharedPreferences..."
   - Should see: "Stored note update request for Flutter to process"

5. **Open app**:
   - Wait for app to fully load
   - Check logcat for Flutter logs:
   ```bash
   adb logcat | grep "FLUTTER NOTE UPDATE"
   ```
   - Should see complete processing flow

6. **Verify in UI**:
   - Go to transaction list
   - Find the Rs 1.00 transaction
   - Note should show "Test note 1" instead of "Imported from SMS"

### Test 2: Add Note to Already Synced Transaction

1. **Send SMS and wait for sync**:
   - Send test SMS
   - Open app immediately
   - Wait for transaction to sync to Drive
   - Close app

2. **Add note via notification**:
   - Notification should still be visible
   - Tap "Add Note"
   - Type: "Added after sync"
   - Submit

3. **Open app again**:
   - Check logcat for note update processing
   - Should see: "Transaction is already in Drive"
   - Should see: "Found X recent transactions (within 5 minutes)"
   - Should see: "Successfully updated note in Drive"

4. **Verify in UI**:
   - Transaction should show "Added after sync"

### Test 3: Multiple Notes

1. **Send 3 test SMS** (different amounts)
2. **Add notes to all 3** via notifications
3. **Open app once**
4. **Verify all 3 notes** appear correctly

## Expected Logcat Output

### Android Side (when adding note):
```
D/KharchaBackground: Note submitted for transaction sms_JM-KOTAKD-S_1_00_1777358324952
D/KharchaBackground: Note text: Hello
D/KharchaBackground: Updated transaction note in SharedPreferences: sms_JM-KOTAKD-S_1_00_1777358324952
D/KharchaBackground: Stored note update request for Flutter to process
D/KharchaBackground: Dismissed notification for transaction sms_JM-KOTAKD-S_1_00_1777358324952
```

### Flutter Side (when opening app):
```
I/flutter: === MAIN: Processing pending transactions and note updates ===
I/flutter: === FLUTTER NOTE UPDATE: Starting note update processing ===
I/flutter: === FLUTTER NOTE UPDATE: Found note update for sms_JM-KOTAKD-S_1_00_1777358324952: "Hello" ===
I/flutter: === FLUTTER NOTE UPDATE: Found 1 pending note updates ===
I/flutter: === FLUTTER NOTE UPDATE: Loading transactions from Drive ===
I/flutter: === FLUTTER NOTE UPDATE: Loaded 5 transactions from Drive ===
I/flutter: === FLUTTER NOTE UPDATE: Processing note update for sms_JM-KOTAKD-S_1_00_1777358324952 ===
I/flutter: === FLUTTER NOTE UPDATE: Found 1 recent transactions (within 5 minutes) ===
I/flutter: === FLUTTER NOTE UPDATE: Using most recent transaction: UPI/123456 ===
I/flutter: === FLUTTER NOTE UPDATE: Updating transaction in Drive: UPI/123456 ===
I/flutter: === FLUTTER NOTE UPDATE: Successfully updated note in Drive ===
I/flutter: === FLUTTER NOTE UPDATE: Refreshing transaction repository ===
I/flutter: === FLUTTER NOTE UPDATE: Repository refreshed successfully ===
I/flutter: === FLUTTER NOTE UPDATE: Note update processing complete ===
I/flutter: === MAIN: Processing complete ===
```

## Troubleshooting

### Issue: No Flutter logs appearing
**Solution**: Use `print()` instead of `debugPrint()` - already fixed in code

### Issue: "No matching transaction found"
**Possible causes**:
1. Transaction is older than 5 minutes
2. Transaction hasn't synced to Drive yet
3. User not signed in to Google

**Solution**: Check if transaction is in pending state or already synced

### Issue: Note shows "Imported from SMS"
**Possible causes**:
1. Note update failed to process
2. Drive update failed
3. Repository not refreshed

**Solution**: Check logcat for error messages in note update flow

### Issue: "Drive access was not granted"
**Solution**: 
1. Sign in to Google account
2. Grant Drive permissions in app settings
3. Try again

## Success Criteria

✅ Note appears in notification after submission
✅ Android logs show note stored in SharedPreferences
✅ Flutter logs show note update processing
✅ Note appears in transaction list in app
✅ Note persists after closing and reopening app
✅ Multiple notes can be added and all appear correctly
