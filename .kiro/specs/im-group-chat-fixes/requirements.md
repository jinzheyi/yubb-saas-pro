# Requirements Document: IM Group Chat Fixes

## Introduction

This document specifies the requirements for fixing critical issues in the group chat functionality of the enterprise IM mobile application (shengyu-ui-admin-uniappx). The system is built with Spring Boot + Netty WebSocket + Protobuf on the backend and uni-app x (UTS language) on the frontend.

The current group chat implementation has three major issues:
1. Personal avatars not displaying properly (showing empty avatarText and avatarBg)
2. Text messages not rendering correctly
3. Sender identification issues in group messages

## Glossary

- **Chat_System**: The IM group chat module in the mobile application
- **Message_Service**: The service layer that handles message sending and receiving (message-service.uts)
- **Avatar_System**: The utility system that generates avatar text and background colors (avatar.uts)
- **User_API**: The backend API for fetching user information (user.uts)
- **Message_Item**: The UI data structure representing a chat message
- **Service_Message**: The internal message format used by Message_Service
- **Server_Message**: The message format received from backend API
- **Group_Chat**: A conversation involving multiple participants
- **Sender_Info**: User information including name, avatar text, and avatar background color

## Requirements

### Requirement 1: Avatar Display in Group Chat

**User Story:** As a user viewing group chat messages, I want to see proper avatars for all message senders, so that I can easily identify who sent each message.

#### Acceptance Criteria

1. WHEN a message is received from the backend API, THE Chat_System SHALL fetch the sender's user information from User_API
2. WHEN sender information is retrieved, THE Avatar_System SHALL generate avatar text using the sender's name
3. WHEN sender information is retrieved, THE Avatar_System SHALL generate avatar background color using the sender's user ID
4. WHEN converting Server_Message to Message_Item, THE Chat_System SHALL populate avatarText and avatarBg fields with the fetched sender information
5. WHEN converting Service_Message to Message_Item, THE Chat_System SHALL populate avatarText and avatarBg fields with the cached sender information
6. WHEN sender information cannot be fetched, THE Chat_System SHALL use fallback values (question mark for text, default color for background)

### Requirement 2: Text Message Content Display

**User Story:** As a user reading group chat messages, I want text messages to display correctly with proper content extraction, so that I can read the actual message content.

#### Acceptance Criteria

1. WHEN a text message is received from the backend, THE Chat_System SHALL parse the content field correctly regardless of JSON structure
2. WHEN the content field is a JSON object with nested content property, THE Chat_System SHALL extract the inner content string
3. WHEN the content field is already a plain string, THE Chat_System SHALL use it directly
4. WHEN displaying text messages in the UI, THE Chat_System SHALL render the extracted content string
5. WHEN text content contains emoji codes, THE Chat_System SHALL parse and display them using the emoji parser

### Requirement 3: Sender Name Display in Group Chat

**User Story:** As a user viewing group chat messages, I want to see the sender's name above each message, so that I can identify who sent the message without relying solely on avatars.

#### Acceptance Criteria

1. WHEN displaying a message in group chat, THE Chat_System SHALL show the sender's name above the message bubble
2. WHEN the sender is the current user, THE Chat_System SHALL not display the sender name (following WeChat pattern)
3. WHEN the sender information includes a group nickname, THE Chat_System SHALL display the group nickname instead of the real name
4. WHEN the sender information is unavailable, THE Chat_System SHALL display a fallback name

### Requirement 4: Message Service Integration

**User Story:** As a developer, I want the Message_Service to properly populate sender information when creating messages, so that the chat UI has all necessary data.

#### Acceptance Criteria

1. WHEN Message_Service creates a new message, THE Message_Service SHALL fetch sender information from User_API
2. WHEN Message_Service receives a message from WebSocket, THE Message_Service SHALL fetch sender information before notifying listeners
3. WHEN sender information is fetched, THE Message_Service SHALL cache it to avoid redundant API calls
4. WHEN Message_Service builds a Service_Message, THE Message_Service SHALL include avatarText, avatarBg, and senderName fields
5. WHEN the current user sends a message, THE Message_Service SHALL use the current user's cached information

### Requirement 5: Content Parsing Consistency

**User Story:** As a developer, I want consistent content parsing across all message conversion functions, so that messages display correctly regardless of their source.

#### Acceptance Criteria

1. WHEN converting Server_Message to Message_Item, THE Chat_System SHALL use a unified content extraction function
2. WHEN converting Service_Message to Message_Item, THE Chat_System SHALL use the same unified content extraction function
3. WHEN the content field structure changes, THE Chat_System SHALL handle both old and new formats gracefully
4. WHEN content parsing fails, THE Chat_System SHALL log the error and display a fallback message

### Requirement 6: User Information Caching

**User Story:** As a system, I want to cache user information to minimize API calls, so that the chat interface remains responsive and reduces backend load.

#### Acceptance Criteria

1. WHEN user information is fetched from User_API, THE Chat_System SHALL cache it in memory
2. WHEN the same user's information is needed again, THE Chat_System SHALL use the cached data
3. WHEN the cache exceeds a reasonable size limit, THE Chat_System SHALL evict least recently used entries
4. WHEN a user's information is updated, THE Chat_System SHALL invalidate the cached entry

### Requirement 7: Error Handling and Fallbacks

**User Story:** As a user, I want the chat to continue functioning even when some data cannot be loaded, so that I can still read and send messages.

#### Acceptance Criteria

1. WHEN User_API fails to fetch sender information, THE Chat_System SHALL use fallback avatar values
2. WHEN content parsing fails, THE Chat_System SHALL display an error indicator instead of crashing
3. WHEN network errors occur during message loading, THE Chat_System SHALL show an error toast and allow retry
4. WHEN avatar generation fails, THE Chat_System SHALL use a default question mark avatar

### Requirement 8: Compatibility with Existing Architecture

**User Story:** As a developer, I want the fixes to maintain compatibility with existing code patterns, so that the system remains maintainable and consistent.

#### Acceptance Criteria

1. WHEN implementing fixes, THE Chat_System SHALL use existing utility functions from avatar.uts
2. WHEN making API calls, THE Chat_System SHALL use the existing request.uts wrapper
3. WHEN updating Message_Service, THE Chat_System SHALL maintain the existing MessageItem and ServiceMessageItem type definitions
4. WHEN modifying message conversion logic, THE Chat_System SHALL preserve backward compatibility with existing message formats
5. WHEN adding new functions, THE Chat_System SHALL follow the existing code style and naming conventions in the codebase
