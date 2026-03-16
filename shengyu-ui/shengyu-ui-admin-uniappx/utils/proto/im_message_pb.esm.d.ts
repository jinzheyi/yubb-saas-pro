import * as $protobuf from "protobufjs";
import Long = require("long");
/** Properties of an ImMessage. */
export interface IImMessage {

    /** ImMessage header */
    header?: (IMessageHeader|null);

    /** ImMessage body */
    body?: (Uint8Array|null);
}

/** Represents an ImMessage. */
export class ImMessage implements IImMessage {

    /**
     * Constructs a new ImMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IImMessage);

    /** ImMessage header. */
    public header?: (IMessageHeader|null);

    /** ImMessage body. */
    public body: Uint8Array;

    /**
     * Creates a new ImMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns ImMessage instance
     */
    public static create(properties?: IImMessage): ImMessage;

    /**
     * Encodes the specified ImMessage message. Does not implicitly {@link ImMessage.verify|verify} messages.
     * @param message ImMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IImMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified ImMessage message, length delimited. Does not implicitly {@link ImMessage.verify|verify} messages.
     * @param message ImMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IImMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an ImMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns ImMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): ImMessage;

    /**
     * Decodes an ImMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns ImMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): ImMessage;

    /**
     * Verifies an ImMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an ImMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns ImMessage
     */
    public static fromObject(object: { [k: string]: any }): ImMessage;

    /**
     * Creates a plain object from an ImMessage message. Also converts values to other types if specified.
     * @param message ImMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: ImMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this ImMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for ImMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Properties of a MessageHeader. */
export interface IMessageHeader {

    /** MessageHeader messageId */
    messageId?: (number|Long|null);

    /** MessageHeader messageType */
    messageType?: (MessageType|null);

    /** MessageHeader senderId */
    senderId?: (number|Long|null);

    /** MessageHeader receiverId */
    receiverId?: (number|Long|null);

    /** MessageHeader groupId */
    groupId?: (number|Long|null);

    /** MessageHeader tenantId */
    tenantId?: (number|Long|null);

    /** MessageHeader timestamp */
    timestamp?: (number|Long|null);

    /** MessageHeader sequence */
    sequence?: (number|Long|null);

    /** MessageHeader extra */
    extra?: (string|null);
}

/** Represents a MessageHeader. */
export class MessageHeader implements IMessageHeader {

    /**
     * Constructs a new MessageHeader.
     * @param [properties] Properties to set
     */
    constructor(properties?: IMessageHeader);

    /** MessageHeader messageId. */
    public messageId: (number|Long);

    /** MessageHeader messageType. */
    public messageType: MessageType;

    /** MessageHeader senderId. */
    public senderId: (number|Long);

    /** MessageHeader receiverId. */
    public receiverId: (number|Long);

    /** MessageHeader groupId. */
    public groupId: (number|Long);

    /** MessageHeader tenantId. */
    public tenantId: (number|Long);

    /** MessageHeader timestamp. */
    public timestamp: (number|Long);

    /** MessageHeader sequence. */
    public sequence: (number|Long);

    /** MessageHeader extra. */
    public extra: string;

    /**
     * Creates a new MessageHeader instance using the specified properties.
     * @param [properties] Properties to set
     * @returns MessageHeader instance
     */
    public static create(properties?: IMessageHeader): MessageHeader;

    /**
     * Encodes the specified MessageHeader message. Does not implicitly {@link MessageHeader.verify|verify} messages.
     * @param message MessageHeader message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IMessageHeader, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified MessageHeader message, length delimited. Does not implicitly {@link MessageHeader.verify|verify} messages.
     * @param message MessageHeader message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IMessageHeader, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a MessageHeader message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns MessageHeader
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): MessageHeader;

    /**
     * Decodes a MessageHeader message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns MessageHeader
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): MessageHeader;

    /**
     * Verifies a MessageHeader message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a MessageHeader message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns MessageHeader
     */
    public static fromObject(object: { [k: string]: any }): MessageHeader;

    /**
     * Creates a plain object from a MessageHeader message. Also converts values to other types if specified.
     * @param message MessageHeader
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: MessageHeader, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this MessageHeader to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for MessageHeader
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** MessageType enum. */
export enum MessageType {
    UNKNOWN = 0,
    HEARTBEAT_REQ = 1,
    HEARTBEAT_RESP = 2,
    AUTH_REQ = 3,
    AUTH_RESP = 4,
    CLOSE = 5,
    ACK = 8,
    ACK_RESP = 9,
    TEXT = 100,
    IMAGE = 101,
    VOICE = 102,
    VIDEO = 103,
    FILE = 104,
    LOCATION = 105,
    CUSTOM = 106,
    SYSTEM_NOTIFY = 200,
    READ_RECEIPT = 201,
    RECALL = 202,
    TYPING = 203,
    BADGE_UPDATE = 204,
    QUOTE_REPLY = 205,
    CALL_SIGNAL = 206,
    WORKFLOW_NOTIFY = 207,
    TODO_REMINDER = 208
}

/** Represents an AuthRequest. */
export class AuthRequest implements IAuthRequest {

    /**
     * Constructs a new AuthRequest.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAuthRequest);

    /** AuthRequest accessToken. */
    public accessToken: string;

    /** AuthRequest deviceType. */
    public deviceType: number;

    /** AuthRequest deviceId. */
    public deviceId: string;

    /** AuthRequest clientVersion. */
    public clientVersion: string;

    /**
     * Creates a new AuthRequest instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AuthRequest instance
     */
    public static create(properties?: IAuthRequest): AuthRequest;

    /**
     * Encodes the specified AuthRequest message. Does not implicitly {@link AuthRequest.verify|verify} messages.
     * @param message AuthRequest message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAuthRequest, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AuthRequest message, length delimited. Does not implicitly {@link AuthRequest.verify|verify} messages.
     * @param message AuthRequest message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAuthRequest, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AuthRequest message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AuthRequest
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AuthRequest;

    /**
     * Decodes an AuthRequest message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AuthRequest
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AuthRequest;

    /**
     * Verifies an AuthRequest message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AuthRequest message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AuthRequest
     */
    public static fromObject(object: { [k: string]: any }): AuthRequest;

    /**
     * Creates a plain object from an AuthRequest message. Also converts values to other types if specified.
     * @param message AuthRequest
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AuthRequest, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AuthRequest to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AuthRequest
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an AuthResponse. */
export class AuthResponse implements IAuthResponse {

    /**
     * Constructs a new AuthResponse.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAuthResponse);

    /** AuthResponse success. */
    public success: boolean;

    /** AuthResponse code. */
    public code: number;

    /** AuthResponse message. */
    public message: string;

    /** AuthResponse userId. */
    public userId: (number|Long);

    /** AuthResponse tenantId. */
    public tenantId: (number|Long);

    /**
     * Creates a new AuthResponse instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AuthResponse instance
     */
    public static create(properties?: IAuthResponse): AuthResponse;

    /**
     * Encodes the specified AuthResponse message. Does not implicitly {@link AuthResponse.verify|verify} messages.
     * @param message AuthResponse message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAuthResponse, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AuthResponse message, length delimited. Does not implicitly {@link AuthResponse.verify|verify} messages.
     * @param message AuthResponse message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAuthResponse, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AuthResponse message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AuthResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AuthResponse;

    /**
     * Decodes an AuthResponse message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AuthResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AuthResponse;

    /**
     * Verifies an AuthResponse message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AuthResponse message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AuthResponse
     */
    public static fromObject(object: { [k: string]: any }): AuthResponse;

    /**
     * Creates a plain object from an AuthResponse message. Also converts values to other types if specified.
     * @param message AuthResponse
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AuthResponse, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AuthResponse to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AuthResponse
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an AckMessage. */
export class AckMessage implements IAckMessage {

    /**
     * Constructs a new AckMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAckMessage);

    /** AckMessage messageId. */
    public messageId: (number|Long);

    /** AckMessage chatId. */
    public chatId: (number|Long);

    /** AckMessage sequence. */
    public sequence: (number|Long);

    /** AckMessage ackType. */
    public ackType: string;

    /** AckMessage clientReceivedAt. */
    public clientReceivedAt: (number|Long);

    /** AckMessage originalTimestamp. */
    public originalTimestamp: (number|Long);

    /**
     * Creates a new AckMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AckMessage instance
     */
    public static create(properties?: IAckMessage): AckMessage;

    /**
     * Encodes the specified AckMessage message. Does not implicitly {@link AckMessage.verify|verify} messages.
     * @param message AckMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAckMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AckMessage message, length delimited. Does not implicitly {@link AckMessage.verify|verify} messages.
     * @param message AckMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAckMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AckMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AckMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AckMessage;

    /**
     * Decodes an AckMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AckMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AckMessage;

    /**
     * Verifies an AckMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AckMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AckMessage
     */
    public static fromObject(object: { [k: string]: any }): AckMessage;

    /**
     * Creates a plain object from an AckMessage message. Also converts values to other types if specified.
     * @param message AckMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AckMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AckMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AckMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an AckResponse. */
export class AckResponse implements IAckResponse {

    /**
     * Constructs a new AckResponse.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAckResponse);

    /** AckResponse success. */
    public success: boolean;

    /** AckResponse code. */
    public code: number;

    /** AckResponse message. */
    public message: string;

    /**
     * Creates a new AckResponse instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AckResponse instance
     */
    public static create(properties?: IAckResponse): AckResponse;

    /**
     * Encodes the specified AckResponse message. Does not implicitly {@link AckResponse.verify|verify} messages.
     * @param message AckResponse message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAckResponse, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AckResponse message, length delimited. Does not implicitly {@link AckResponse.verify|verify} messages.
     * @param message AckResponse message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAckResponse, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AckResponse message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AckResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AckResponse;

    /**
     * Decodes an AckResponse message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AckResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AckResponse;

    /**
     * Verifies an AckResponse message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AckResponse message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AckResponse
     */
    public static fromObject(object: { [k: string]: any }): AckResponse;

    /**
     * Creates a plain object from an AckResponse message. Also converts values to other types if specified.
     * @param message AckResponse
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AckResponse, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AckResponse to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AckResponse
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a TextMessage. */
export class TextMessage implements ITextMessage {

    /**
     * Constructs a new TextMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ITextMessage);

    /** TextMessage content. */
    public content: string;

    /** TextMessage atUserIds. */
    public atUserIds: (number|Long)[];

    /**
     * Creates a new TextMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns TextMessage instance
     */
    public static create(properties?: ITextMessage): TextMessage;

    /**
     * Encodes the specified TextMessage message. Does not implicitly {@link TextMessage.verify|verify} messages.
     * @param message TextMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ITextMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified TextMessage message, length delimited. Does not implicitly {@link TextMessage.verify|verify} messages.
     * @param message TextMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ITextMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a TextMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns TextMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): TextMessage;

    /**
     * Decodes a TextMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns TextMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): TextMessage;

    /**
     * Verifies a TextMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a TextMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns TextMessage
     */
    public static fromObject(object: { [k: string]: any }): TextMessage;

    /**
     * Creates a plain object from a TextMessage message. Also converts values to other types if specified.
     * @param message TextMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: TextMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this TextMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for TextMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an ImageMessage. */
export class ImageMessage implements IImageMessage {

    /**
     * Constructs a new ImageMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IImageMessage);

    /** ImageMessage url. */
    public url: string;

    /** ImageMessage thumbnailUrl. */
    public thumbnailUrl: string;

    /** ImageMessage width. */
    public width: number;

    /** ImageMessage height. */
    public height: number;

    /** ImageMessage size. */
    public size: (number|Long);

    /**
     * Creates a new ImageMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns ImageMessage instance
     */
    public static create(properties?: IImageMessage): ImageMessage;

    /**
     * Encodes the specified ImageMessage message. Does not implicitly {@link ImageMessage.verify|verify} messages.
     * @param message ImageMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IImageMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified ImageMessage message, length delimited. Does not implicitly {@link ImageMessage.verify|verify} messages.
     * @param message ImageMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IImageMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an ImageMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns ImageMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): ImageMessage;

    /**
     * Decodes an ImageMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns ImageMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): ImageMessage;

    /**
     * Verifies an ImageMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an ImageMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns ImageMessage
     */
    public static fromObject(object: { [k: string]: any }): ImageMessage;

    /**
     * Creates a plain object from an ImageMessage message. Also converts values to other types if specified.
     * @param message ImageMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: ImageMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this ImageMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for ImageMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a VoiceMessage. */
export class VoiceMessage implements IVoiceMessage {

    /**
     * Constructs a new VoiceMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IVoiceMessage);

    /** VoiceMessage url. */
    public url: string;

    /** VoiceMessage duration. */
    public duration: number;

    /** VoiceMessage size. */
    public size: (number|Long);

    /**
     * Creates a new VoiceMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns VoiceMessage instance
     */
    public static create(properties?: IVoiceMessage): VoiceMessage;

    /**
     * Encodes the specified VoiceMessage message. Does not implicitly {@link VoiceMessage.verify|verify} messages.
     * @param message VoiceMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IVoiceMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified VoiceMessage message, length delimited. Does not implicitly {@link VoiceMessage.verify|verify} messages.
     * @param message VoiceMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IVoiceMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a VoiceMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns VoiceMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): VoiceMessage;

    /**
     * Decodes a VoiceMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns VoiceMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): VoiceMessage;

    /**
     * Verifies a VoiceMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a VoiceMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns VoiceMessage
     */
    public static fromObject(object: { [k: string]: any }): VoiceMessage;

    /**
     * Creates a plain object from a VoiceMessage message. Also converts values to other types if specified.
     * @param message VoiceMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: VoiceMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this VoiceMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for VoiceMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a VideoMessage. */
export class VideoMessage implements IVideoMessage {

    /**
     * Constructs a new VideoMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IVideoMessage);

    /** VideoMessage url. */
    public url: string;

    /** VideoMessage coverUrl. */
    public coverUrl: string;

    /** VideoMessage duration. */
    public duration: number;

    /** VideoMessage width. */
    public width: number;

    /** VideoMessage height. */
    public height: number;

    /** VideoMessage size. */
    public size: (number|Long);

    /**
     * Creates a new VideoMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns VideoMessage instance
     */
    public static create(properties?: IVideoMessage): VideoMessage;

    /**
     * Encodes the specified VideoMessage message. Does not implicitly {@link VideoMessage.verify|verify} messages.
     * @param message VideoMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IVideoMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified VideoMessage message, length delimited. Does not implicitly {@link VideoMessage.verify|verify} messages.
     * @param message VideoMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IVideoMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a VideoMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns VideoMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): VideoMessage;

    /**
     * Decodes a VideoMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns VideoMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): VideoMessage;

    /**
     * Verifies a VideoMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a VideoMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns VideoMessage
     */
    public static fromObject(object: { [k: string]: any }): VideoMessage;

    /**
     * Creates a plain object from a VideoMessage message. Also converts values to other types if specified.
     * @param message VideoMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: VideoMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this VideoMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for VideoMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a FileMessage. */
export class FileMessage implements IFileMessage {

    /**
     * Constructs a new FileMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IFileMessage);

    /** FileMessage url. */
    public url: string;

    /** FileMessage fileName. */
    public fileName: string;

    /** FileMessage size. */
    public size: (number|Long);

    /** FileMessage fileType. */
    public fileType: string;

    /**
     * Creates a new FileMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns FileMessage instance
     */
    public static create(properties?: IFileMessage): FileMessage;

    /**
     * Encodes the specified FileMessage message. Does not implicitly {@link FileMessage.verify|verify} messages.
     * @param message FileMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IFileMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified FileMessage message, length delimited. Does not implicitly {@link FileMessage.verify|verify} messages.
     * @param message FileMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IFileMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a FileMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns FileMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): FileMessage;

    /**
     * Decodes a FileMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns FileMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): FileMessage;

    /**
     * Verifies a FileMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a FileMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns FileMessage
     */
    public static fromObject(object: { [k: string]: any }): FileMessage;

    /**
     * Creates a plain object from a FileMessage message. Also converts values to other types if specified.
     * @param message FileMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: FileMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this FileMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for FileMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a LocationMessage. */
export class LocationMessage implements ILocationMessage {

    /**
     * Constructs a new LocationMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ILocationMessage);

    /** LocationMessage latitude. */
    public latitude: number;

    /** LocationMessage longitude. */
    public longitude: number;

    /** LocationMessage address. */
    public address: string;

    /**
     * Creates a new LocationMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns LocationMessage instance
     */
    public static create(properties?: ILocationMessage): LocationMessage;

    /**
     * Encodes the specified LocationMessage message. Does not implicitly {@link LocationMessage.verify|verify} messages.
     * @param message LocationMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ILocationMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified LocationMessage message, length delimited. Does not implicitly {@link LocationMessage.verify|verify} messages.
     * @param message LocationMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ILocationMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a LocationMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns LocationMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): LocationMessage;

    /**
     * Decodes a LocationMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns LocationMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): LocationMessage;

    /**
     * Verifies a LocationMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a LocationMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns LocationMessage
     */
    public static fromObject(object: { [k: string]: any }): LocationMessage;

    /**
     * Creates a plain object from a LocationMessage message. Also converts values to other types if specified.
     * @param message LocationMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: LocationMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this LocationMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for LocationMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a ReadReceiptMessage. */
export class ReadReceiptMessage implements IReadReceiptMessage {

    /**
     * Constructs a new ReadReceiptMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IReadReceiptMessage);

    /** ReadReceiptMessage messageIds. */
    public messageIds: (number|Long)[];

    /**
     * Creates a new ReadReceiptMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns ReadReceiptMessage instance
     */
    public static create(properties?: IReadReceiptMessage): ReadReceiptMessage;

    /**
     * Encodes the specified ReadReceiptMessage message. Does not implicitly {@link ReadReceiptMessage.verify|verify} messages.
     * @param message ReadReceiptMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IReadReceiptMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified ReadReceiptMessage message, length delimited. Does not implicitly {@link ReadReceiptMessage.verify|verify} messages.
     * @param message ReadReceiptMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IReadReceiptMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a ReadReceiptMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns ReadReceiptMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): ReadReceiptMessage;

    /**
     * Decodes a ReadReceiptMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns ReadReceiptMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): ReadReceiptMessage;

    /**
     * Verifies a ReadReceiptMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a ReadReceiptMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns ReadReceiptMessage
     */
    public static fromObject(object: { [k: string]: any }): ReadReceiptMessage;

    /**
     * Creates a plain object from a ReadReceiptMessage message. Also converts values to other types if specified.
     * @param message ReadReceiptMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: ReadReceiptMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this ReadReceiptMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for ReadReceiptMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a RecallMessage. */
export class RecallMessage implements IRecallMessage {

    /**
     * Constructs a new RecallMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IRecallMessage);

    /** RecallMessage messageId. */
    public messageId: (number|Long);

    /**
     * Creates a new RecallMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns RecallMessage instance
     */
    public static create(properties?: IRecallMessage): RecallMessage;

    /**
     * Encodes the specified RecallMessage message. Does not implicitly {@link RecallMessage.verify|verify} messages.
     * @param message RecallMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IRecallMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified RecallMessage message, length delimited. Does not implicitly {@link RecallMessage.verify|verify} messages.
     * @param message RecallMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IRecallMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a RecallMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns RecallMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): RecallMessage;

    /**
     * Decodes a RecallMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns RecallMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): RecallMessage;

    /**
     * Verifies a RecallMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a RecallMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns RecallMessage
     */
    public static fromObject(object: { [k: string]: any }): RecallMessage;

    /**
     * Creates a plain object from a RecallMessage message. Also converts values to other types if specified.
     * @param message RecallMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: RecallMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this RecallMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for RecallMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a QuoteReplyMessage. */
export class QuoteReplyMessage implements IQuoteReplyMessage {

    /**
     * Constructs a new QuoteReplyMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IQuoteReplyMessage);

    /** QuoteReplyMessage quoteMessageId. */
    public quoteMessageId: (number|Long);

    /** QuoteReplyMessage quoteContent. */
    public quoteContent: string;

    /** QuoteReplyMessage quoteSenderId. */
    public quoteSenderId: (number|Long);

    /** QuoteReplyMessage quoteSenderName. */
    public quoteSenderName: string;

    /** QuoteReplyMessage replyContent. */
    public replyContent: string;

    /** QuoteReplyMessage atUserIds. */
    public atUserIds: (number|Long)[];

    /**
     * Creates a new QuoteReplyMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns QuoteReplyMessage instance
     */
    public static create(properties?: IQuoteReplyMessage): QuoteReplyMessage;

    /**
     * Encodes the specified QuoteReplyMessage message. Does not implicitly {@link QuoteReplyMessage.verify|verify} messages.
     * @param message QuoteReplyMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IQuoteReplyMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified QuoteReplyMessage message, length delimited. Does not implicitly {@link QuoteReplyMessage.verify|verify} messages.
     * @param message QuoteReplyMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IQuoteReplyMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a QuoteReplyMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns QuoteReplyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): QuoteReplyMessage;

    /**
     * Decodes a QuoteReplyMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns QuoteReplyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): QuoteReplyMessage;

    /**
     * Verifies a QuoteReplyMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a QuoteReplyMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns QuoteReplyMessage
     */
    public static fromObject(object: { [k: string]: any }): QuoteReplyMessage;

    /**
     * Creates a plain object from a QuoteReplyMessage message. Also converts values to other types if specified.
     * @param message QuoteReplyMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: QuoteReplyMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this QuoteReplyMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for QuoteReplyMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a TypingMessage. */
export class TypingMessage implements ITypingMessage {

    /**
     * Constructs a new TypingMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ITypingMessage);

    /** TypingMessage targetUserId. */
    public targetUserId: (number|Long);

    /** TypingMessage groupId. */
    public groupId: (number|Long);

    /** TypingMessage isTyping. */
    public isTyping: boolean;

    /**
     * Creates a new TypingMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns TypingMessage instance
     */
    public static create(properties?: ITypingMessage): TypingMessage;

    /**
     * Encodes the specified TypingMessage message. Does not implicitly {@link TypingMessage.verify|verify} messages.
     * @param message TypingMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ITypingMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified TypingMessage message, length delimited. Does not implicitly {@link TypingMessage.verify|verify} messages.
     * @param message TypingMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ITypingMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a TypingMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns TypingMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): TypingMessage;

    /**
     * Decodes a TypingMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns TypingMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): TypingMessage;

    /**
     * Verifies a TypingMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a TypingMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns TypingMessage
     */
    public static fromObject(object: { [k: string]: any }): TypingMessage;

    /**
     * Creates a plain object from a TypingMessage message. Also converts values to other types if specified.
     * @param message TypingMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: TypingMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this TypingMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for TypingMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a BadgeUpdateMessage. */
export class BadgeUpdateMessage implements IBadgeUpdateMessage {

    /**
     * Constructs a new BadgeUpdateMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IBadgeUpdateMessage);

    /** BadgeUpdateMessage unreadCount. */
    public unreadCount: number;

    /** BadgeUpdateMessage conversationBadges. */
    public conversationBadges: IConversationBadge[];

    /** BadgeUpdateMessage menuBadges. */
    public menuBadges: IMenuBadge[];

    /**
     * Creates a new BadgeUpdateMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns BadgeUpdateMessage instance
     */
    public static create(properties?: IBadgeUpdateMessage): BadgeUpdateMessage;

    /**
     * Encodes the specified BadgeUpdateMessage message. Does not implicitly {@link BadgeUpdateMessage.verify|verify} messages.
     * @param message BadgeUpdateMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IBadgeUpdateMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified BadgeUpdateMessage message, length delimited. Does not implicitly {@link BadgeUpdateMessage.verify|verify} messages.
     * @param message BadgeUpdateMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IBadgeUpdateMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a BadgeUpdateMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns BadgeUpdateMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): BadgeUpdateMessage;

    /**
     * Decodes a BadgeUpdateMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns BadgeUpdateMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): BadgeUpdateMessage;

    /**
     * Verifies a BadgeUpdateMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a BadgeUpdateMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns BadgeUpdateMessage
     */
    public static fromObject(object: { [k: string]: any }): BadgeUpdateMessage;

    /**
     * Creates a plain object from a BadgeUpdateMessage message. Also converts values to other types if specified.
     * @param message BadgeUpdateMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: BadgeUpdateMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this BadgeUpdateMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for BadgeUpdateMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a ConversationBadge. */
export class ConversationBadge implements IConversationBadge {

    /**
     * Constructs a new ConversationBadge.
     * @param [properties] Properties to set
     */
    constructor(properties?: IConversationBadge);

    /** ConversationBadge conversationId. */
    public conversationId: (number|Long);

    /** ConversationBadge unreadCount. */
    public unreadCount: number;

    /**
     * Creates a new ConversationBadge instance using the specified properties.
     * @param [properties] Properties to set
     * @returns ConversationBadge instance
     */
    public static create(properties?: IConversationBadge): ConversationBadge;

    /**
     * Encodes the specified ConversationBadge message. Does not implicitly {@link ConversationBadge.verify|verify} messages.
     * @param message ConversationBadge message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IConversationBadge, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified ConversationBadge message, length delimited. Does not implicitly {@link ConversationBadge.verify|verify} messages.
     * @param message ConversationBadge message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IConversationBadge, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a ConversationBadge message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns ConversationBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): ConversationBadge;

    /**
     * Decodes a ConversationBadge message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns ConversationBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): ConversationBadge;

    /**
     * Verifies a ConversationBadge message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a ConversationBadge message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns ConversationBadge
     */
    public static fromObject(object: { [k: string]: any }): ConversationBadge;

    /**
     * Creates a plain object from a ConversationBadge message. Also converts values to other types if specified.
     * @param message ConversationBadge
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: ConversationBadge, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this ConversationBadge to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for ConversationBadge
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a MenuBadge. */
export class MenuBadge implements IMenuBadge {

    /**
     * Constructs a new MenuBadge.
     * @param [properties] Properties to set
     */
    constructor(properties?: IMenuBadge);

    /** MenuBadge menuId. */
    public menuId: string;

    /** MenuBadge badgeCount. */
    public badgeCount: number;

    /**
     * Creates a new MenuBadge instance using the specified properties.
     * @param [properties] Properties to set
     * @returns MenuBadge instance
     */
    public static create(properties?: IMenuBadge): MenuBadge;

    /**
     * Encodes the specified MenuBadge message. Does not implicitly {@link MenuBadge.verify|verify} messages.
     * @param message MenuBadge message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IMenuBadge, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified MenuBadge message, length delimited. Does not implicitly {@link MenuBadge.verify|verify} messages.
     * @param message MenuBadge message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IMenuBadge, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a MenuBadge message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns MenuBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): MenuBadge;

    /**
     * Decodes a MenuBadge message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns MenuBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): MenuBadge;

    /**
     * Verifies a MenuBadge message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a MenuBadge message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns MenuBadge
     */
    public static fromObject(object: { [k: string]: any }): MenuBadge;

    /**
     * Creates a plain object from a MenuBadge message. Also converts values to other types if specified.
     * @param message MenuBadge
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: MenuBadge, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this MenuBadge to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for MenuBadge
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a CallSignalMessage. */
export class CallSignalMessage implements ICallSignalMessage {

    /**
     * Constructs a new CallSignalMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ICallSignalMessage);

    /** CallSignalMessage callId. */
    public callId: string;

    /** CallSignalMessage callType. */
    public callType: number;

    /** CallSignalMessage signalType. */
    public signalType: number;

    /** CallSignalMessage callerId. */
    public callerId: (number|Long);

    /** CallSignalMessage calleeId. */
    public calleeId: (number|Long);

    /** CallSignalMessage rejectReason. */
    public rejectReason: string;

    /** CallSignalMessage extraData. */
    public extraData: string;

    /**
     * Creates a new CallSignalMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns CallSignalMessage instance
     */
    public static create(properties?: ICallSignalMessage): CallSignalMessage;

    /**
     * Encodes the specified CallSignalMessage message. Does not implicitly {@link CallSignalMessage.verify|verify} messages.
     * @param message CallSignalMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ICallSignalMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified CallSignalMessage message, length delimited. Does not implicitly {@link CallSignalMessage.verify|verify} messages.
     * @param message CallSignalMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ICallSignalMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a CallSignalMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns CallSignalMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): CallSignalMessage;

    /**
     * Decodes a CallSignalMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns CallSignalMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): CallSignalMessage;

    /**
     * Verifies a CallSignalMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a CallSignalMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns CallSignalMessage
     */
    public static fromObject(object: { [k: string]: any }): CallSignalMessage;

    /**
     * Creates a plain object from a CallSignalMessage message. Also converts values to other types if specified.
     * @param message CallSignalMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: CallSignalMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this CallSignalMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for CallSignalMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a WorkflowNotifyMessage. */
export class WorkflowNotifyMessage implements IWorkflowNotifyMessage {

    /**
     * Constructs a new WorkflowNotifyMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: IWorkflowNotifyMessage);

    /** WorkflowNotifyMessage processInstanceId. */
    public processInstanceId: string;

    /** WorkflowNotifyMessage processName. */
    public processName: string;

    /** WorkflowNotifyMessage initiatorId. */
    public initiatorId: (number|Long);

    /** WorkflowNotifyMessage initiatorName. */
    public initiatorName: string;

    /** WorkflowNotifyMessage content. */
    public content: string;

    /** WorkflowNotifyMessage buttons. */
    public buttons: IWorkflowButton[];

    /** WorkflowNotifyMessage status. */
    public status: number;

    /** WorkflowNotifyMessage jumpUrl. */
    public jumpUrl: string;

    /**
     * Creates a new WorkflowNotifyMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns WorkflowNotifyMessage instance
     */
    public static create(properties?: IWorkflowNotifyMessage): WorkflowNotifyMessage;

    /**
     * Encodes the specified WorkflowNotifyMessage message. Does not implicitly {@link WorkflowNotifyMessage.verify|verify} messages.
     * @param message WorkflowNotifyMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IWorkflowNotifyMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified WorkflowNotifyMessage message, length delimited. Does not implicitly {@link WorkflowNotifyMessage.verify|verify} messages.
     * @param message WorkflowNotifyMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IWorkflowNotifyMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a WorkflowNotifyMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns WorkflowNotifyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): WorkflowNotifyMessage;

    /**
     * Decodes a WorkflowNotifyMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns WorkflowNotifyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): WorkflowNotifyMessage;

    /**
     * Verifies a WorkflowNotifyMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a WorkflowNotifyMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns WorkflowNotifyMessage
     */
    public static fromObject(object: { [k: string]: any }): WorkflowNotifyMessage;

    /**
     * Creates a plain object from a WorkflowNotifyMessage message. Also converts values to other types if specified.
     * @param message WorkflowNotifyMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: WorkflowNotifyMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this WorkflowNotifyMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for WorkflowNotifyMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a WorkflowButton. */
export class WorkflowButton implements IWorkflowButton {

    /**
     * Constructs a new WorkflowButton.
     * @param [properties] Properties to set
     */
    constructor(properties?: IWorkflowButton);

    /** WorkflowButton buttonId. */
    public buttonId: string;

    /** WorkflowButton buttonText. */
    public buttonText: string;

    /** WorkflowButton buttonType. */
    public buttonType: number;

    /**
     * Creates a new WorkflowButton instance using the specified properties.
     * @param [properties] Properties to set
     * @returns WorkflowButton instance
     */
    public static create(properties?: IWorkflowButton): WorkflowButton;

    /**
     * Encodes the specified WorkflowButton message. Does not implicitly {@link WorkflowButton.verify|verify} messages.
     * @param message WorkflowButton message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IWorkflowButton, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified WorkflowButton message, length delimited. Does not implicitly {@link WorkflowButton.verify|verify} messages.
     * @param message WorkflowButton message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IWorkflowButton, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a WorkflowButton message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns WorkflowButton
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): WorkflowButton;

    /**
     * Decodes a WorkflowButton message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns WorkflowButton
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): WorkflowButton;

    /**
     * Verifies a WorkflowButton message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a WorkflowButton message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns WorkflowButton
     */
    public static fromObject(object: { [k: string]: any }): WorkflowButton;

    /**
     * Creates a plain object from a WorkflowButton message. Also converts values to other types if specified.
     * @param message WorkflowButton
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: WorkflowButton, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this WorkflowButton to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for WorkflowButton
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a TodoReminderMessage. */
export class TodoReminderMessage implements ITodoReminderMessage {

    /**
     * Constructs a new TodoReminderMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ITodoReminderMessage);

    /** TodoReminderMessage todoId. */
    public todoId: string;

    /** TodoReminderMessage title. */
    public title: string;

    /** TodoReminderMessage content. */
    public content: string;

    /** TodoReminderMessage dueTime. */
    public dueTime: (number|Long);

    /** TodoReminderMessage reminderType. */
    public reminderType: number;

    /** TodoReminderMessage jumpUrl. */
    public jumpUrl: string;

    /** TodoReminderMessage status. */
    public status: number;

    /**
     * Creates a new TodoReminderMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns TodoReminderMessage instance
     */
    public static create(properties?: ITodoReminderMessage): TodoReminderMessage;

    /**
     * Encodes the specified TodoReminderMessage message. Does not implicitly {@link TodoReminderMessage.verify|verify} messages.
     * @param message TodoReminderMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ITodoReminderMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified TodoReminderMessage message, length delimited. Does not implicitly {@link TodoReminderMessage.verify|verify} messages.
     * @param message TodoReminderMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ITodoReminderMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a TodoReminderMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns TodoReminderMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): TodoReminderMessage;

    /**
     * Decodes a TodoReminderMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns TodoReminderMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): TodoReminderMessage;

    /**
     * Verifies a TodoReminderMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a TodoReminderMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns TodoReminderMessage
     */
    public static fromObject(object: { [k: string]: any }): TodoReminderMessage;

    /**
     * Creates a plain object from a TodoReminderMessage message. Also converts values to other types if specified.
     * @param message TodoReminderMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: TodoReminderMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this TodoReminderMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for TodoReminderMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}
