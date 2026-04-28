# Note Update Architecture

## Overview
This document explains how notes added via notification are processed and synced to Google Drive.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER FLOW                                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. SMS Received → Transaction Notification with "Add Note"     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. User taps "Add Note" → Types note → Submits                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           ANDROID SIDE (Background Processing)                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ NotificationActionReceiver.handleNoteSubmitted()          │  │
│  │                                                           │  │
│  │ 1. Extract note text from RemoteInput                    │  │
│  │ 2. Update transaction in SharedPreferences:              │  │
│  │    - Update 'note' field in transaction JSON             │  │
│  │ 3. Store note update request:                            │  │
│  │    - Key: pending_note_update_{transactionId}            │  │
│  │    - Value: note text                                    │  │
│  │ 4. Dismiss notification                                  │  │
│  │ 5. Enqueue DriveSyncWorker (attempts background sync)    │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  SharedPreferences Storage:                                      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ pending_transaction_{id} = {transaction JSON with note}   │  │
│  │ pending_note_update_{id} = "note text"                    │  │
│  │ pending_note_update_timestamp_{id} = timestamp            │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. User Opens App                                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│           FLUTTER SIDE (App Startup)                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ main.dart                                                 │  │
│  │ └─> FlutterStartupReader.processPendingTransactions()    │  │
│  │     └─> _applyNoteUpdatesToExistingTransactions()        │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Note Update Processing Logic                                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 1. Read all pending_note_update_* keys                   │  │
│  │                                                           │  │
│  │ 2. For each note update:                                 │  │
│  │    ┌─────────────────────────────────────────────────┐   │  │
│  │    │ Check if transaction is still pending           │   │  │
│  │    │ (not yet synced to Drive)                       │   │  │
│  │    └─────────────────────────────────────────────────┘   │  │
│  │              │                                            │  │
│  │              ├─ YES: Update note in pending JSON         │  │
│  │              │      (will be synced with note)           │  │
│  │              │                                            │  │
│  │              └─ NO: Transaction already in Drive         │  │
│  │                     ┌─────────────────────────────────┐  │  │
│  │                     │ Load transactions from Drive    │  │  │
│  │                     │ Find most recent (< 5 minutes)  │  │  │
│  │                     │ Update in Drive via API         │  │  │
│  │                     └─────────────────────────────────┘  │  │
│  │                                                           │  │
│  │ 3. Remove processed note update keys                     │  │
│  │ 4. Refresh TransactionRepository                         │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Google Drive Update                                             │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ DriveBackupService.updateTransactionInDrive()             │  │
│  │                                                           │  │
│  │ 1. Authenticate with Google                              │  │
│  │ 2. Read transactions.json from Drive                     │  │
│  │ 3. Find matching transaction by ID                       │  │
│  │ 4. Update note field                                     │  │
│  │ 5. Write updated transactions.json back to Drive        │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  UI Update                                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ TransactionRepository.loadTransactions(forceRefresh: true)│  │
│  │ └─> Notifies listeners (Home, Ledger screens)            │  │
│  │     └─> UI rebuilds with updated notes                   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. User sees note in transaction list ✓                        │
└─────────────────────────────────────────────────────────────────┘
```

## Key Components

### 1. NotificationActionReceiver (Android)
**File**: `android/app/src/main/kotlin/com/example/kharcha/background/NotificationActionReceiver.kt`

**Responsibilities**:
- Handle note submission from notification RemoteInput
- Update transaction in SharedPreferences
- Store note update request for Flutter processing
- Dismiss notification
- Trigger background sync attempt

**Key Methods**:
- `handleNoteSubmitted()`: Main entry point for note submission

### 2. FlutterStartupReader (Flutter)
**File**: `lib/utils/background/flutter_startup_reader.dart`

**Responsibilities**:
- Process pending transactions on app startup
- Apply note updates to transactions
- Handle both pending and already-synced transactions
- Coordinate with Drive backup service

**Key Methods**:
- `processPendingTransactions()`: Main entry point called from main.dart
- `_applyNoteUpdatesToExistingTransactions()`: Core note update logic

### 3. DriveBackupService (Flutter)
**File**: `lib/utils/drive/drive_backup_service.dart`

**Responsibilities**:
- Authenticate with Google Drive
- Read/write transactions.json file
- Update individual transactions
- Handle Drive API errors

**Key Methods**:
- `updateTransactionInDrive()`: Update a single transaction in Drive

### 4. TransactionRepository (Flutter)
**File**: `lib/utils/drive/transaction_repository.dart`

**Responsibilities**:
- Cache transactions in memory
- Notify UI of changes
- Prevent redundant Drive API calls

**Key Methods**:
- `loadTransactions()`: Load from Drive with caching
- `updateTransactions()`: Update cache and notify listeners

## Data Flow

### SharedPreferences Keys

1. **Transaction Storage**:
   ```
   pending_transaction_{transactionId} = {
     "rawMessage": "...",
     "amount": 1.00,
     "note": "User's note",
     ...
   }
   ```

2. **Note Update Request**:
   ```
   pending_note_update_{transactionId} = "User's note"
   pending_note_update_timestamp_{transactionId} = 1714358324952
   ```

### Transaction Matching Logic

When finding a transaction to update:

1. **First Priority**: Check if transaction is still pending
   - Look for `pending_transaction_{transactionId}` key
   - If found, update note in pending JSON
   - Transaction will be synced to Drive with note

2. **Second Priority**: Find in Drive by recency
   - Load all transactions from Drive
   - Filter transactions within last 5 minutes
   - Sort by date (most recent first)
   - Use most recent transaction

### Why 5 Minutes?

The 5-minute window is chosen because:
- SMS notifications are typically acted upon quickly
- Reduces chance of matching wrong transaction
- Balances between being too strict and too loose
- Can be adjusted if needed

## Error Handling

### Scenario 1: Drive Update Fails
- Note update request remains in SharedPreferences
- Will be retried on next app open
- User can manually retry by reopening app

### Scenario 2: No Matching Transaction
- Note update request is removed (can't be processed)
- Logged for debugging
- User would need to add note manually in app

### Scenario 3: User Not Signed In
- Drive operations fail gracefully
- Transactions remain in SharedPreferences
- Will be processed when user signs in

### Scenario 4: Network Error
- Drive API calls fail
- Transactions remain in SharedPreferences
- Will be retried on next app open

## Performance Considerations

### Startup Time
- Note processing happens before UI renders
- Typically completes in < 1 second
- Does not block UI thread
- Errors don't prevent app from starting

### Drive API Calls
- Only called when note updates exist
- Batched with transaction sync when possible
- Cached in TransactionRepository to avoid redundant calls

### Memory Usage
- Minimal - only stores note text in SharedPreferences
- Transactions loaded into memory only during processing
- Repository caches transactions for UI

## Security Considerations

### Data Privacy
- Notes stored locally in SharedPreferences (private to app)
- Synced to user's personal Google Drive
- Not shared with any third parties

### Authentication
- Requires Google sign-in
- Drive access must be explicitly granted
- Uses OAuth 2.0 for secure authentication

### Data Integrity
- Transaction IDs are unique and deterministic
- Note updates are atomic (all or nothing)
- Drive file is validated before writing

## Future Improvements

### Potential Enhancements
1. **Offline Support**: Queue note updates when offline
2. **Conflict Resolution**: Handle concurrent updates from multiple devices
3. **Note History**: Track note edit history
4. **Rich Text**: Support formatting in notes
5. **Voice Notes**: Add audio note support
6. **Note Templates**: Predefined note templates for common scenarios

### Performance Optimizations
1. **Incremental Sync**: Only sync changed transactions
2. **Background Sync**: Use WorkManager for periodic sync
3. **Compression**: Compress Drive file for faster transfers
4. **Caching**: More aggressive caching strategies

## Debugging Tips

### Enable Verbose Logging
All note update operations use `print()` with `===` markers:
```bash
adb logcat | grep "FLUTTER NOTE UPDATE"
```

### Check SharedPreferences
```bash
adb shell run-as com.harsh.kharcha cat /data/data/com.harsh.kharcha/shared_prefs/kharcha_background.xml
```

### Monitor Drive API Calls
Look for Drive-related logs:
```bash
adb logcat | grep -E "(Drive|Google)"
```

### Test Without Device
Use Flutter integration tests to simulate note updates without physical device.

## Conclusion

This architecture provides a robust, user-friendly way to add notes to transactions via notifications. The key design decisions are:

1. **Simplicity**: Single processing flow in FlutterStartupReader
2. **Reliability**: Persistent storage in SharedPreferences with retry logic
3. **Performance**: Efficient Drive API usage with caching
4. **User Experience**: Immediate feedback with background sync

The system handles edge cases gracefully and provides clear logging for debugging.
