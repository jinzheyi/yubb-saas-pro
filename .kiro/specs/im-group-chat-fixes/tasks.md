# Implementation Plan: IM Group Chat Fixes

## Overview

This implementation plan fixes three critical issues in group chat through simple field mapping corrections:

1. **Avatar Display Issue**: Fix field name from `msg.senderName` to `msg.senderNickname`
2. **Message Type Mapping**: Fix type numbers from 100-105 to 1-6
3. **Sender Name Display**: Add sender name UI element in group chat

The backend already provides all necessary data - no caching or additional API calls needed!

## Tasks

- [ ] 1. Fix message conversion field mapping in chat.uvue
  - Fix line ~580: Change `msg.senderName` to `msg.senderNickname`
  - Add `senderName: msg.senderNickname || ''` to MessageItem
  - Ensure avatarText uses `msg.senderNickname`
  - _Requirements: 1.1, 1.2, 1.4_

- [ ] 2. Fix message type mapping in chat.uvue
  - Update `getMessageTypeString()` function (line ~600)
  - Change type map from 100-105 to 1-6
  - Map: 1→'text', 2→'image', 3→'voice', 4→'video', 5→'file', 6→'location'
  - _Requirements: 2.1, 5.1_

- [ ] 2.1 Write property test for message type mapping
  - **Property 2: Message Type Mapping Consistency**
  - **Validates: Requirements 2.1, 5.1**

- [ ] 3. Fix message content extraction in chat.uvue
  - Update `getMessageContent()` function (line ~620)
  - Change all type checks from 100-105 to 1-6
  - Update: `messageType === 100` → `messageType === 1`, etc.
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3.1 Write property test for content extraction
  - **Property 5: Content Extraction Format Flexibility**
  - **Validates: Requirements 2.1, 2.2, 2.3, 5.3**

- [ ] 4. Update Message_Service to populate sender information
  - [ ] 4.1 Add imports to message-service.uts
    - Import `getAvatarText` and `getUserAvatarColor` from '@/utils/avatar.uts'
    - Import user store if needed
    - _Requirements: 4.1_
  
  - [ ] 4.2 Fix sendMessage() method (line ~330)
    - Get current user info from user store
    - Populate avatarText using `getAvatarText(currentUser.nickname || currentUser.username)`
    - Populate avatarBg using `getUserAvatarColor(this.currentUserId)`
    - Populate senderName with current user's nickname or username
    - _Requirements: 4.4, 4.5_
  
  - [ ] 4.3 Fix handleReceivedMessage() method (line ~370)
    - Populate avatarBg using `getUserAvatarColor(message.header.senderId)`
    - Use placeholder '?' for avatarText (will be correct when loading history)
    - Use empty string for senderName (will be correct when loading history)
    - _Requirements: 4.2_

- [ ] 4.4 Write property test for service message completeness
  - **Property 8: Service Message Completeness**
  - **Validates: Requirements 4.4**

- [ ] 5. Add sender name display to group chat UI
  - [ ] 5.1 Add sender name template element in chat.uvue
    - Add conditional text element above message bubble
    - Show only in group chat (chatType === 'group')
    - Hide for self messages (msg.isSelf === true)
    - Display msg.senderName
    - _Requirements: 3.1, 3.2_
  
  - [ ] 5.2 Add sender name styling
    - Create .sender-name CSS class
    - Font size: 12px, color: #8F959E
    - Add margin-bottom: 4px
    - _Requirements: 3.1_

- [ ] 5.3 Write unit test for sender name display logic
  - Test group chat shows sender name
  - Test single chat hides sender name
  - Test self messages hide sender name
  - **Validates: Requirements 3.1, 3.2**

- [ ] 6. Add error handling
  - [ ] 6.1 Add content parsing error handling
    - Wrap JSON.parse in try-catch if needed
    - Return raw string on parse failure
    - Log parsing errors
    - _Requirements: 7.2_
  
  - [ ] 6.2 Add fallback for missing sender info
    - Use empty string for missing senderNickname
    - Use "?" for avatarText if name is empty
    - _Requirements: 7.1_
  
  - [ ] 6.3 Add error toasts for network failures
    - Show toast when message loading fails
    - _Requirements: 7.3_

- [ ] 6.4 Write unit tests for error scenarios
  - Test malformed content handling
  - Test missing sender info handling
  - Test network error handling
  - **Validates: Requirements 7.1, 7.2, 7.3**

- [ ] 7. Write property tests for avatar generation
  - **Property 3: Avatar Text Generation Consistency**
  - **Property 4: Avatar Color Determinism**
  - **Validates: Requirements 1.2, 1.3**

- [ ] 8. Final checkpoint - Comprehensive testing
  - Run all unit tests
  - Run all property tests
  - Manual testing in group chat
  - Verify avatars display correctly
  - Verify sender names appear in group chat
  - Verify text messages display correctly
  - Test all message types (text, image, voice, video, file, location)

## Notes

- This is a SIMPLIFIED solution - no UserInfoCache needed!
- Backend already provides senderNickname and senderAvatar
- The fix is primarily field name and type number corrections
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- All changes maintain compatibility with existing WebSocket and Protobuf protocol
