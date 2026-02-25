# Design Document: IM Group Chat Fixes

## Overview

This design addresses three critical issues in the group chat functionality:

1. **Avatar Display Issue**: Messages show empty avatarText and avatarBg because the message conversion functions don't fetch user information from the backend
2. **Text Content Display Issue**: Text messages may not display correctly due to inconsistent content field parsing (sometimes nested JSON, sometimes plain string)
3. **Sender Identification Issue**: Group chat messages lack sender name display, making it difficult to identify who sent each message

The solution involves:
- Adding user information fetching logic with caching
- Standardizing content extraction across all message conversion functions
- Enhancing the UI to display sender names in group chat
- Updating Message_Service to populate sender information

## Architecture

### Current Architecture

```
chat.uvue (UI Layer)
    ↓
message-service.uts (Service Layer)
    ↓
websocket.uts (Transport Layer)
    ↓
Backend API (Spring Boot + Netty)
```

### Root Cause Analysis

After thorough code review, the issues are **NOT** due to missing backend data. The backend already provides all necessary information:

**Backend (Working Correctly)**:
- `AppImMessageRespVO` returns `senderNickname` and `senderAvatar` fields
- `ImMessageServiceImpl.fillSenderInfo()` already fetches user info from database
- Message types: 1=text, 2=image, 3=voice, 4=video, 5=file, 6=location

**Frontend (Has Bugs)**:
1. **Wrong field name**: Line ~580 uses `msg.senderName` but backend returns `msg.senderNickname`
2. **Wrong type mapping**: `getMessageTypeString()` maps 100-105 but backend returns 1-6
3. **Wrong type checks**: `getMessageContent()` checks `messageType === 100` but should check `=== 1`
4. **Empty fields**: `message-service.uts` creates messages with empty `avatarText`, `avatarBg`, `senderName`

### Simplified Solution

**NO UserInfoCache needed** - backend already provides all data!

The fix is simple field mapping corrections:
1. Fix field name: `msg.senderName` → `msg.senderNickname`
2. Fix type mapping: 100-105 → 1-6 in `getMessageTypeString()`
3. Fix type checks: Update `getMessageContent()` to use 1-6
4. Populate avatar fields in MessageService using existing utilities
5. Add sender name display in group chat UI

## Components and Interfaces

### 1. Fix Message Conversion in chat.uvue

**Location**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`

**Changes Required**:

```typescript
// Fix field name mapping (line ~580)
function convertServerMessage(msg: any): MessageItem {
  return {
    id: msg.id.toString(),
    messageId: msg.messageId,
    senderId: msg.senderId.toString(),
    receiverId: msg.receiverId ? msg.receiverId.toString() : '',
    type: getMessageTypeString(msg.messageType),
    content: getMessageContent(msg.messageType, content),
    isSelf: msg.senderId === currentUserId.value,
    time: msg.createTime,
    timestamp: new Date(msg.createTime).getTime(),
    showTime: true,
    avatarText: getAvatarTextUtil(msg.senderNickname || ''),  // FIX: was msg.senderName
    avatarBg: getUserAvatarColor(msg.senderId),
    senderName: msg.senderNickname || '',  // ADD: populate sender name
    status: msg.status === 1 ? 'success' : 'sending'
  } as MessageItem
}

// Fix message type mapping (line ~600)
function getMessageTypeString(messageType: number): string {
  const typeMap = {
    1: 'text',    // FIX: was 100
    2: 'image',   // FIX: was 101
    3: 'voice',   // FIX: was 102
    4: 'video',   // FIX: was 103
    5: 'file',    // FIX: was 104
    6: 'location' // FIX: was 105
  }
  return typeMap[messageType] || 'text'
}

// Fix message type checks (line ~620)
function getMessageContent(messageType: number, content: any): string {
  if (messageType === 1) {  // FIX: was 100
    return content.content || content
  } else if (messageType === 2) {  // FIX: was 101
    return content.url || content
  } else if (messageType === 3) {  // FIX: was 102
    return content.url || content
  } else if (messageType === 4) {  // FIX: was 103
    return content.url || content
  } else if (messageType === 5) {  // FIX: was 104
    return content.url || content
  } else if (messageType === 6) {  // FIX: was 105
    return content.address || content
  }
  return content.toString()
}
```

### 2. Fix Message Service

**Location**: `shengyu-ui/shengyu-ui-admin-uniappx/services/message-service.uts`

**Changes Required**:

```typescript
// Import utilities at top of file
import { getAvatarText, getUserAvatarColor } from '@/utils/avatar.uts'

// Fix sendMessage() to populate avatar fields (line ~330)
private sendMessage(message: ImMessage): MessageItem {
  // Get current user info from store
  const userStore = useUserStore()
  const currentUser = userStore.userInfo
  
  const messageItem: MessageItem = {
    id: 0,
    messageId: message.header.messageId,
    senderId: message.header.senderId,
    receiverId: message.header.receiverId,
    groupId: message.header.groupId,
    type: message.header.messageType,
    content: message.body,
    status: MessageStatus.SENDING,
    timestamp: message.header.timestamp,
    isSelf: true,
    showTime: true,
    avatarText: getAvatarText(currentUser.nickname || currentUser.username),  // FIX: populate
    avatarBg: getUserAvatarColor(this.currentUserId),  // FIX: populate
    senderName: currentUser.nickname || currentUser.username  // FIX: populate
  }
  
  // ... rest of logic
}

// Fix handleReceivedMessage() to populate avatar fields (line ~370)
private handleReceivedMessage(data: any): void {
  const message = data as ImMessage
  
  // For received messages via WebSocket, use placeholder values
  // Real sender info will be populated when loading message history from API
  
  const messageItem: MessageItem = {
    id: 0,
    messageId: message.header.messageId,
    senderId: message.header.senderId,
    receiverId: message.header.receiverId,
    groupId: message.header.groupId,
    type: message.header.messageType,
    content: message.body,
    status: MessageStatus.SENT,
    timestamp: message.header.timestamp,
    isSelf: message.header.senderId === this.currentUserId,
    showTime: true,
    avatarText: '?',  // Placeholder - will be correct when loading history
    avatarBg: getUserAvatarColor(message.header.senderId),
    senderName: ''  // Placeholder - will be correct when loading history
  }
  
  // ... rest of logic
}
```

### 3. Add Sender Name Display in UI

**Location**: `shengyu-ui/shengyu-ui-admin-uniappx/pages/message/chat.uvue`

**Template Changes**:

```html
<!-- Add sender name display for group chat -->
<view class="message-bubble-wrap">
  <!-- Sender name (only in group chat, only for others' messages) -->
  <text v-if="chatType === 'group' && !msg.isSelf" class="sender-name">
    {{ msg.senderName }}
  </text>
  
  <!-- Message bubble (existing) -->
  <view v-if="msg.type === 'text'" class="message-bubble bubble-text">
    <!-- ... existing content -->
  </view>
</view>
```

**CSS Styling**:

```css
.sender-name {
  font-size: 12px;
  color: #8F959E;
  margin-bottom: 4px;
}
```

## Data Models

### MessageItem (No Changes Needed)

The existing MessageItem type already has all required fields:

```typescript
type MessageItem = {
  id: string
  messageId: number
  senderId: string
  receiverId: string
  type: string
  content: string
  isSelf: boolean
  time: string
  timestamp: number
  showTime: boolean
  avatarText: string        // Will be properly populated
  avatarBg: string          // Will be properly populated
  senderName: string        // Will be properly populated (was empty before)
  duration?: number
  poster?: string
  fileName?: string
  fileSize?: string
  address?: string
  isSticker?: boolean
  status?: string
}
```

## Implementation Flow

### Flow 1: Loading Historical Messages

```
1. User opens group chat
2. chat.uvue calls loadMessages()
3. Backend API returns message list with senderNickname and senderAvatar
4. For each message:
   a. Extract msg.senderNickname (not msg.senderName!)
   b. Generate avatarText using getAvatarText(msg.senderNickname)
   c. Generate avatarBg using getUserAvatarColor(msg.senderId)
   d. Set senderName to msg.senderNickname
5. Convert to MessageItem with populated fields
6. Render in UI with sender names visible in group chat
```

### Flow 2: Receiving New Messages via WebSocket

```
1. WebSocket receives message
2. Message_Service.handleReceivedMessage() called
3. Create MessageItem with placeholder avatar values
4. Notify message listeners
5. chat.uvue receives notification
6. Add message to messages array
7. UI renders with placeholder (will be corrected on next history load)
```

### Flow 3: Sending Messages

```
1. User types and sends message
2. chat.uvue calls messageService.sendTextMessage()
3. Message_Service fetches current user info from store
4. Create MessageItem with current user's avatar info
5. Add to local message list (optimistic UI)
6. Send via WebSocket
7. Backend processes and broadcasts
8. Receive confirmation via WebSocket
```


## Correctness Properties

A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do.

### Property 1: Field Name Mapping Correctness

*For any* message received from backend API, the conversion function should use `msg.senderNickname` (not `msg.senderName`) to populate avatar and sender name fields

**Validates: Requirements 1.1, 1.4**

### Property 2: Message Type Mapping Consistency

*For any* message type number from backend (1-6), the type mapping function should return the correct string type ('text', 'image', 'voice', 'video', 'file', 'location')

**Validates: Requirements 2.1, 5.1**

### Property 3: Avatar Text Generation Consistency

*For any* user name string, the Avatar_System should generate the same avatar text every time it is called with that name

**Validates: Requirements 1.2**

### Property 4: Avatar Color Determinism

*For any* user ID, the Avatar_System should generate the same background color every time it is called with that user ID

**Validates: Requirements 1.3**

### Property 5: Content Extraction Format Flexibility

*For any* message content field (whether JSON string, JSON object, or plain string), the content extraction function should successfully extract a displayable string without throwing errors

**Validates: Requirements 2.1, 2.2, 2.3, 5.3**

### Property 6: Sender Name Display in Group Chat

*For any* group chat message where isSelf is false, the rendered UI should include a visible sender name element above the message bubble

**Validates: Requirements 3.1**

### Property 7: Sender Name Hidden for Self Messages

*For any* message where isSelf is true, the rendered UI should not include a sender name element

**Validates: Requirements 3.2**

### Property 8: Service Message Completeness

*For any* Service_Message created by Message_Service for sent messages, the message should include non-empty avatarText, avatarBg, and senderName fields

**Validates: Requirements 4.4**

## Error Handling

### Error Scenarios and Responses

1. **Content Parsing Failure**:
   - Scenario: JSON.parse() throws exception or content is malformed
   - Response: Return the raw content string as fallback
   - Log parsing error with content sample
   - Display content as-is without blocking message display

2. **Network Errors During Message Loading**:
   - Scenario: getMessageList API fails
   - Response: Show toast "加载消息失败"
   - Keep existing messages visible
   - Allow user to retry by pulling down to refresh

3. **Avatar Generation Failure**:
   - Scenario: getAvatarText() or getUserAvatarColor() throws exception
   - Response: Use default values ("?", "#999999")
   - Log error
   - Continue rendering message

4. **Missing Sender Information**:
   - Scenario: Backend returns message without senderNickname
   - Response: Use empty string for senderName, "?" for avatarText
   - Continue rendering message
   - Log warning for debugging

### Error Handling Principles

- **Graceful Degradation**: Never block message display due to missing metadata
- **User Feedback**: Show toasts for user-actionable errors (network failures)
- **Silent Fallbacks**: Use default values for non-critical failures (avatar generation)
- **Logging**: Log all errors for debugging and monitoring

## Testing Strategy

### Dual Testing Approach

This feature requires both unit testing and property-based testing:

**Unit Tests**: Focus on specific examples and edge cases
- Test specific field name mappings (senderNickname vs senderName)
- Test specific message type mappings (1-6 vs 100-105)
- Test specific user names (Chinese, English, empty)
- Test specific content formats (nested, flat, malformed)

**Property Tests**: Verify universal properties across all inputs
- Test avatar generation with random user IDs (consistency)
- Test content extraction with randomly generated JSON structures
- Test message type mapping with all valid type numbers
- Test message conversion with random message data

### Property-Based Testing Configuration

**Library**: fast-check (for UTS/TypeScript)

**Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with: **Feature: im-group-chat-fixes, Property {number}: {property_text}**
- Use appropriate generators for user IDs, names, message structures

**Test Organization**:
```
tests/
  unit/
    message-conversion.test.ts
    content-extraction.test.ts
    avatar-generation.test.ts
  property/
    avatar-generation.property.test.ts
    content-parsing.property.test.ts
    message-conversion.property.test.ts
```

### Integration Testing

**Manual Testing Checklist**:
1. Open group chat with multiple participants
2. Verify all avatars display with correct colors and text
3. Send text messages and verify they display correctly
4. Receive messages and verify sender names appear
5. Test with various content formats (plain text, emoji, long text)
6. Test with network failures (airplane mode)
7. Verify message type mapping works for all types (text, image, voice, video, file, location)

**Automated Integration Tests**:
- Test complete message flow from API to UI
- Test WebSocket message reception
- Test error recovery scenarios

### Test Coverage Goals

- Unit test coverage: 80%+ for modified code
- Property test coverage: All identified properties (8 properties)
- Integration test coverage: All user-facing flows
- Edge case coverage: All error scenarios in Error Handling section
