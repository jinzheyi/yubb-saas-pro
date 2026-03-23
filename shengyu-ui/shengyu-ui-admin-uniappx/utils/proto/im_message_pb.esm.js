/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
import * as $protobuf from "protobufjs/minimal";
import Long from "long";

// Common aliases
const $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

if ($protobuf.util.Long !== Long) {
    $protobuf.util.Long = Long;
    $protobuf.configure();
}

// Exported root namespace
const $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

export const ImMessage = $root.ImMessage = (() => {

    /**
     * Properties of an ImMessage.
     * @exports IImMessage
     * @interface IImMessage
     * @property {IMessageHeader|null} [header] ImMessage header
     * @property {Uint8Array|null} [body] ImMessage body
     */

    /**
     * Constructs a new ImMessage.
     * @exports ImMessage
     * @classdesc Represents an ImMessage.
     * @implements IImMessage
     * @constructor
     * @param {IImMessage=} [properties] Properties to set
     */
    function ImMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * ImMessage header.
     * @member {IMessageHeader|null|undefined} header
     * @memberof ImMessage
     * @instance
     */
    ImMessage.prototype.header = null;

    /**
     * ImMessage body.
     * @member {Uint8Array} body
     * @memberof ImMessage
     * @instance
     */
    ImMessage.prototype.body = $util.newBuffer([]);

    /**
     * Creates a new ImMessage instance using the specified properties.
     * @function create
     * @memberof ImMessage
     * @static
     * @param {IImMessage=} [properties] Properties to set
     * @returns {ImMessage} ImMessage instance
     */
    ImMessage.create = function create(properties) {
        return new ImMessage(properties);
    };

    /**
     * Encodes the specified ImMessage message. Does not implicitly {@link ImMessage.verify|verify} messages.
     * @function encode
     * @memberof ImMessage
     * @static
     * @param {IImMessage} message ImMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ImMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.header != null && Object.hasOwnProperty.call(message, "header"))
            $root.MessageHeader.encode(message.header, writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
        if (message.body != null && Object.hasOwnProperty.call(message, "body"))
            writer.uint32(/* id 2, wireType 2 =*/18).bytes(message.body);
        return writer;
    };

    /**
     * Encodes the specified ImMessage message, length delimited. Does not implicitly {@link ImMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof ImMessage
     * @static
     * @param {IImMessage} message ImMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ImMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an ImMessage message from the specified reader or buffer.
     * @function decode
     * @memberof ImMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {ImMessage} ImMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ImMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.ImMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.header = $root.MessageHeader.decode(reader, reader.uint32());
                    break;
                }
            case 2: {
                    message.body = reader.bytes();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an ImMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof ImMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {ImMessage} ImMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ImMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an ImMessage message.
     * @function verify
     * @memberof ImMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    ImMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.header != null && message.hasOwnProperty("header")) {
            let error = $root.MessageHeader.verify(message.header);
            if (error)
                return "header." + error;
        }
        if (message.body != null && message.hasOwnProperty("body"))
            if (!(message.body && typeof message.body.length === "number" || $util.isString(message.body)))
                return "body: buffer expected";
        return null;
    };

    /**
     * Creates an ImMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof ImMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {ImMessage} ImMessage
     */
    ImMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.ImMessage)
            return object;
        let message = new $root.ImMessage();
        if (object.header != null) {
            if (typeof object.header !== "object")
                throw TypeError(".ImMessage.header: object expected");
            message.header = $root.MessageHeader.fromObject(object.header);
        }
        if (object.body != null)
            if (typeof object.body === "string")
                $util.base64.decode(object.body, message.body = $util.newBuffer($util.base64.length(object.body)), 0);
            else if (object.body.length >= 0)
                message.body = object.body;
        return message;
    };

    /**
     * Creates a plain object from an ImMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof ImMessage
     * @static
     * @param {ImMessage} message ImMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    ImMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.header = null;
            if (options.bytes === String)
                object.body = "";
            else {
                object.body = [];
                if (options.bytes !== Array)
                    object.body = $util.newBuffer(object.body);
            }
        }
        if (message.header != null && message.hasOwnProperty("header"))
            object.header = $root.MessageHeader.toObject(message.header, options);
        if (message.body != null && message.hasOwnProperty("body"))
            object.body = options.bytes === String ? $util.base64.encode(message.body, 0, message.body.length) : options.bytes === Array ? Array.prototype.slice.call(message.body) : message.body;
        return object;
    };

    /**
     * Converts this ImMessage to JSON.
     * @function toJSON
     * @memberof ImMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    ImMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for ImMessage
     * @function getTypeUrl
     * @memberof ImMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    ImMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/ImMessage";
    };

    return ImMessage;
})();

export const MessageHeader = $root.MessageHeader = (() => {

    /**
     * Properties of a MessageHeader.
     * @exports IMessageHeader
     * @interface IMessageHeader
     * @property {number|Long|null} [messageId] MessageHeader messageId
     * @property {MessageType|null} [messageType] MessageHeader messageType
     * @property {number|Long|null} [senderId] MessageHeader senderId
     * @property {number|Long|null} [receiverId] MessageHeader receiverId
     * @property {number|Long|null} [groupId] MessageHeader groupId
     * @property {number|Long|null} [tenantId] MessageHeader tenantId
     * @property {number|Long|null} [timestamp] MessageHeader timestamp
     * @property {number|Long|null} [sequence] MessageHeader sequence
     * @property {string|null} [extra] MessageHeader extra
     */

    /**
     * Constructs a new MessageHeader.
     * @exports MessageHeader
     * @classdesc Represents a MessageHeader.
     * @implements IMessageHeader
     * @constructor
     * @param {IMessageHeader=} [properties] Properties to set
     */
    function MessageHeader(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * MessageHeader messageId.
     * @member {number|Long} messageId
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.messageId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader messageType.
     * @member {MessageType} messageType
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.messageType = 0;

    /**
     * MessageHeader senderId.
     * @member {number|Long} senderId
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.senderId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader receiverId.
     * @member {number|Long} receiverId
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.receiverId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader groupId.
     * @member {number|Long} groupId
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.groupId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader tenantId.
     * @member {number|Long} tenantId
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.tenantId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader timestamp.
     * @member {number|Long} timestamp
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.timestamp = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader sequence.
     * @member {number|Long} sequence
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.sequence = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MessageHeader extra.
     * @member {string} extra
     * @memberof MessageHeader
     * @instance
     */
    MessageHeader.prototype.extra = "";

    /**
     * Creates a new MessageHeader instance using the specified properties.
     * @function create
     * @memberof MessageHeader
     * @static
     * @param {IMessageHeader=} [properties] Properties to set
     * @returns {MessageHeader} MessageHeader instance
     */
    MessageHeader.create = function create(properties) {
        return new MessageHeader(properties);
    };

    /**
     * Encodes the specified MessageHeader message. Does not implicitly {@link MessageHeader.verify|verify} messages.
     * @function encode
     * @memberof MessageHeader
     * @static
     * @param {IMessageHeader} message MessageHeader message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MessageHeader.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.messageId != null && Object.hasOwnProperty.call(message, "messageId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.messageId);
        if (message.messageType != null && Object.hasOwnProperty.call(message, "messageType"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.messageType);
        if (message.senderId != null && Object.hasOwnProperty.call(message, "senderId"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.senderId);
        if (message.receiverId != null && Object.hasOwnProperty.call(message, "receiverId"))
            writer.uint32(/* id 4, wireType 0 =*/32).int64(message.receiverId);
        if (message.groupId != null && Object.hasOwnProperty.call(message, "groupId"))
            writer.uint32(/* id 5, wireType 0 =*/40).int64(message.groupId);
        if (message.tenantId != null && Object.hasOwnProperty.call(message, "tenantId"))
            writer.uint32(/* id 6, wireType 0 =*/48).int64(message.tenantId);
        if (message.timestamp != null && Object.hasOwnProperty.call(message, "timestamp"))
            writer.uint32(/* id 7, wireType 0 =*/56).int64(message.timestamp);
        if (message.sequence != null && Object.hasOwnProperty.call(message, "sequence"))
            writer.uint32(/* id 8, wireType 0 =*/64).int64(message.sequence);
        if (message.extra != null && Object.hasOwnProperty.call(message, "extra"))
            writer.uint32(/* id 9, wireType 2 =*/74).string(message.extra);
        return writer;
    };

    /**
     * Encodes the specified MessageHeader message, length delimited. Does not implicitly {@link MessageHeader.verify|verify} messages.
     * @function encodeDelimited
     * @memberof MessageHeader
     * @static
     * @param {IMessageHeader} message MessageHeader message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MessageHeader.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a MessageHeader message from the specified reader or buffer.
     * @function decode
     * @memberof MessageHeader
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {MessageHeader} MessageHeader
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MessageHeader.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.MessageHeader();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.messageId = reader.int64();
                    break;
                }
            case 2: {
                    message.messageType = reader.int32();
                    break;
                }
            case 3: {
                    message.senderId = reader.int64();
                    break;
                }
            case 4: {
                    message.receiverId = reader.int64();
                    break;
                }
            case 5: {
                    message.groupId = reader.int64();
                    break;
                }
            case 6: {
                    message.tenantId = reader.int64();
                    break;
                }
            case 7: {
                    message.timestamp = reader.int64();
                    break;
                }
            case 8: {
                    message.sequence = reader.int64();
                    break;
                }
            case 9: {
                    message.extra = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a MessageHeader message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof MessageHeader
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {MessageHeader} MessageHeader
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MessageHeader.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a MessageHeader message.
     * @function verify
     * @memberof MessageHeader
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    MessageHeader.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (!$util.isInteger(message.messageId) && !(message.messageId && $util.isInteger(message.messageId.low) && $util.isInteger(message.messageId.high)))
                return "messageId: integer|Long expected";
        if (message.messageType != null && message.hasOwnProperty("messageType"))
            switch (message.messageType) {
            default:
                return "messageType: enum value expected";
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
            case 5:
            case 8:
            case 9:
            case 100:
            case 101:
            case 102:
            case 103:
            case 104:
            case 105:
            case 106:
            case 200:
            case 201:
            case 202:
            case 203:
            case 204:
            case 205:
            case 206:
            case 207:
            case 208:
                break;
            }
        if (message.senderId != null && message.hasOwnProperty("senderId"))
            if (!$util.isInteger(message.senderId) && !(message.senderId && $util.isInteger(message.senderId.low) && $util.isInteger(message.senderId.high)))
                return "senderId: integer|Long expected";
        if (message.receiverId != null && message.hasOwnProperty("receiverId"))
            if (!$util.isInteger(message.receiverId) && !(message.receiverId && $util.isInteger(message.receiverId.low) && $util.isInteger(message.receiverId.high)))
                return "receiverId: integer|Long expected";
        if (message.groupId != null && message.hasOwnProperty("groupId"))
            if (!$util.isInteger(message.groupId) && !(message.groupId && $util.isInteger(message.groupId.low) && $util.isInteger(message.groupId.high)))
                return "groupId: integer|Long expected";
        if (message.tenantId != null && message.hasOwnProperty("tenantId"))
            if (!$util.isInteger(message.tenantId) && !(message.tenantId && $util.isInteger(message.tenantId.low) && $util.isInteger(message.tenantId.high)))
                return "tenantId: integer|Long expected";
        if (message.timestamp != null && message.hasOwnProperty("timestamp"))
            if (!$util.isInteger(message.timestamp) && !(message.timestamp && $util.isInteger(message.timestamp.low) && $util.isInteger(message.timestamp.high)))
                return "timestamp: integer|Long expected";
        if (message.sequence != null && message.hasOwnProperty("sequence"))
            if (!$util.isInteger(message.sequence) && !(message.sequence && $util.isInteger(message.sequence.low) && $util.isInteger(message.sequence.high)))
                return "sequence: integer|Long expected";
        if (message.extra != null && message.hasOwnProperty("extra"))
            if (!$util.isString(message.extra))
                return "extra: string expected";
        return null;
    };

    /**
     * Creates a MessageHeader message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof MessageHeader
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {MessageHeader} MessageHeader
     */
    MessageHeader.fromObject = function fromObject(object) {
        if (object instanceof $root.MessageHeader)
            return object;
        let message = new $root.MessageHeader();
        if (object.messageId != null)
            if ($util.Long)
                (message.messageId = $util.Long.fromValue(object.messageId)).unsigned = false;
            else if (typeof object.messageId === "string")
                message.messageId = parseInt(object.messageId, 10);
            else if (typeof object.messageId === "number")
                message.messageId = object.messageId;
            else if (typeof object.messageId === "object")
                message.messageId = new $util.LongBits(object.messageId.low >>> 0, object.messageId.high >>> 0).toNumber();
        switch (object.messageType) {
        default:
            if (typeof object.messageType === "number") {
                message.messageType = object.messageType;
                break;
            }
            break;
        case "UNKNOWN":
        case 0:
            message.messageType = 0;
            break;
        case "HEARTBEAT_REQ":
        case 1:
            message.messageType = 1;
            break;
        case "HEARTBEAT_RESP":
        case 2:
            message.messageType = 2;
            break;
        case "AUTH_REQ":
        case 3:
            message.messageType = 3;
            break;
        case "AUTH_RESP":
        case 4:
            message.messageType = 4;
            break;
        case "CLOSE":
        case 5:
            message.messageType = 5;
            break;
        case "ACK":
        case 8:
            message.messageType = 8;
            break;
        case "ACK_RESP":
        case 9:
            message.messageType = 9;
            break;
        case "TEXT":
        case 100:
            message.messageType = 100;
            break;
        case "IMAGE":
        case 101:
            message.messageType = 101;
            break;
        case "VOICE":
        case 102:
            message.messageType = 102;
            break;
        case "VIDEO":
        case 103:
            message.messageType = 103;
            break;
        case "FILE":
        case 104:
            message.messageType = 104;
            break;
        case "LOCATION":
        case 105:
            message.messageType = 105;
            break;
        case "CUSTOM":
        case 106:
            message.messageType = 106;
            break;
        case "SYSTEM_NOTIFY":
        case 200:
            message.messageType = 200;
            break;
        case "READ_RECEIPT":
        case 201:
            message.messageType = 201;
            break;
        case "RECALL":
        case 202:
            message.messageType = 202;
            break;
        case "TYPING":
        case 203:
            message.messageType = 203;
            break;
        case "BADGE_UPDATE":
        case 204:
            message.messageType = 204;
            break;
        case "QUOTE_REPLY":
        case 205:
            message.messageType = 205;
            break;
        case "CALL_SIGNAL":
        case 206:
            message.messageType = 206;
            break;
        case "WORKFLOW_NOTIFY":
        case 207:
            message.messageType = 207;
            break;
        case "TODO_REMINDER":
        case 208:
            message.messageType = 208;
            break;
        }
        if (object.senderId != null)
            if ($util.Long)
                (message.senderId = $util.Long.fromValue(object.senderId)).unsigned = false;
            else if (typeof object.senderId === "string")
                message.senderId = parseInt(object.senderId, 10);
            else if (typeof object.senderId === "number")
                message.senderId = object.senderId;
            else if (typeof object.senderId === "object")
                message.senderId = new $util.LongBits(object.senderId.low >>> 0, object.senderId.high >>> 0).toNumber();
        if (object.receiverId != null)
            if ($util.Long)
                (message.receiverId = $util.Long.fromValue(object.receiverId)).unsigned = false;
            else if (typeof object.receiverId === "string")
                message.receiverId = parseInt(object.receiverId, 10);
            else if (typeof object.receiverId === "number")
                message.receiverId = object.receiverId;
            else if (typeof object.receiverId === "object")
                message.receiverId = new $util.LongBits(object.receiverId.low >>> 0, object.receiverId.high >>> 0).toNumber();
        if (object.groupId != null)
            if ($util.Long)
                (message.groupId = $util.Long.fromValue(object.groupId)).unsigned = false;
            else if (typeof object.groupId === "string")
                message.groupId = parseInt(object.groupId, 10);
            else if (typeof object.groupId === "number")
                message.groupId = object.groupId;
            else if (typeof object.groupId === "object")
                message.groupId = new $util.LongBits(object.groupId.low >>> 0, object.groupId.high >>> 0).toNumber();
        if (object.tenantId != null)
            if ($util.Long)
                (message.tenantId = $util.Long.fromValue(object.tenantId)).unsigned = false;
            else if (typeof object.tenantId === "string")
                message.tenantId = parseInt(object.tenantId, 10);
            else if (typeof object.tenantId === "number")
                message.tenantId = object.tenantId;
            else if (typeof object.tenantId === "object")
                message.tenantId = new $util.LongBits(object.tenantId.low >>> 0, object.tenantId.high >>> 0).toNumber();
        if (object.timestamp != null)
            if ($util.Long)
                (message.timestamp = $util.Long.fromValue(object.timestamp)).unsigned = false;
            else if (typeof object.timestamp === "string")
                message.timestamp = parseInt(object.timestamp, 10);
            else if (typeof object.timestamp === "number")
                message.timestamp = object.timestamp;
            else if (typeof object.timestamp === "object")
                message.timestamp = new $util.LongBits(object.timestamp.low >>> 0, object.timestamp.high >>> 0).toNumber();
        if (object.sequence != null)
            if ($util.Long)
                (message.sequence = $util.Long.fromValue(object.sequence)).unsigned = false;
            else if (typeof object.sequence === "string")
                message.sequence = parseInt(object.sequence, 10);
            else if (typeof object.sequence === "number")
                message.sequence = object.sequence;
            else if (typeof object.sequence === "object")
                message.sequence = new $util.LongBits(object.sequence.low >>> 0, object.sequence.high >>> 0).toNumber();
        if (object.extra != null)
            message.extra = String(object.extra);
        return message;
    };

    /**
     * Creates a plain object from a MessageHeader message. Also converts values to other types if specified.
     * @function toObject
     * @memberof MessageHeader
     * @static
     * @param {MessageHeader} message MessageHeader
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    MessageHeader.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.messageId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.messageId = options.longs === String ? "0" : 0;
            object.messageType = options.enums === String ? "UNKNOWN" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.senderId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.senderId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.receiverId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.receiverId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.groupId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.groupId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.tenantId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.tenantId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.timestamp = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.timestamp = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.sequence = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.sequence = options.longs === String ? "0" : 0;
            object.extra = "";
        }
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (typeof message.messageId === "number")
                object.messageId = options.longs === String ? String(message.messageId) : message.messageId;
            else
                object.messageId = options.longs === String ? $util.Long.prototype.toString.call(message.messageId) : options.longs === Number ? new $util.LongBits(message.messageId.low >>> 0, message.messageId.high >>> 0).toNumber() : message.messageId;
        if (message.messageType != null && message.hasOwnProperty("messageType"))
            object.messageType = options.enums === String ? $root.MessageType[message.messageType] === undefined ? message.messageType : $root.MessageType[message.messageType] : message.messageType;
        if (message.senderId != null && message.hasOwnProperty("senderId"))
            if (typeof message.senderId === "number")
                object.senderId = options.longs === String ? String(message.senderId) : message.senderId;
            else
                object.senderId = options.longs === String ? $util.Long.prototype.toString.call(message.senderId) : options.longs === Number ? new $util.LongBits(message.senderId.low >>> 0, message.senderId.high >>> 0).toNumber() : message.senderId;
        if (message.receiverId != null && message.hasOwnProperty("receiverId"))
            if (typeof message.receiverId === "number")
                object.receiverId = options.longs === String ? String(message.receiverId) : message.receiverId;
            else
                object.receiverId = options.longs === String ? $util.Long.prototype.toString.call(message.receiverId) : options.longs === Number ? new $util.LongBits(message.receiverId.low >>> 0, message.receiverId.high >>> 0).toNumber() : message.receiverId;
        if (message.groupId != null && message.hasOwnProperty("groupId"))
            if (typeof message.groupId === "number")
                object.groupId = options.longs === String ? String(message.groupId) : message.groupId;
            else
                object.groupId = options.longs === String ? $util.Long.prototype.toString.call(message.groupId) : options.longs === Number ? new $util.LongBits(message.groupId.low >>> 0, message.groupId.high >>> 0).toNumber() : message.groupId;
        if (message.tenantId != null && message.hasOwnProperty("tenantId"))
            if (typeof message.tenantId === "number")
                object.tenantId = options.longs === String ? String(message.tenantId) : message.tenantId;
            else
                object.tenantId = options.longs === String ? $util.Long.prototype.toString.call(message.tenantId) : options.longs === Number ? new $util.LongBits(message.tenantId.low >>> 0, message.tenantId.high >>> 0).toNumber() : message.tenantId;
        if (message.timestamp != null && message.hasOwnProperty("timestamp"))
            if (typeof message.timestamp === "number")
                object.timestamp = options.longs === String ? String(message.timestamp) : message.timestamp;
            else
                object.timestamp = options.longs === String ? $util.Long.prototype.toString.call(message.timestamp) : options.longs === Number ? new $util.LongBits(message.timestamp.low >>> 0, message.timestamp.high >>> 0).toNumber() : message.timestamp;
        if (message.sequence != null && message.hasOwnProperty("sequence"))
            if (typeof message.sequence === "number")
                object.sequence = options.longs === String ? String(message.sequence) : message.sequence;
            else
                object.sequence = options.longs === String ? $util.Long.prototype.toString.call(message.sequence) : options.longs === Number ? new $util.LongBits(message.sequence.low >>> 0, message.sequence.high >>> 0).toNumber() : message.sequence;
        if (message.extra != null && message.hasOwnProperty("extra"))
            object.extra = message.extra;
        return object;
    };

    /**
     * Converts this MessageHeader to JSON.
     * @function toJSON
     * @memberof MessageHeader
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    MessageHeader.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for MessageHeader
     * @function getTypeUrl
     * @memberof MessageHeader
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    MessageHeader.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/MessageHeader";
    };

    return MessageHeader;
})();

/**
 * MessageType enum.
 * @exports MessageType
 * @enum {number}
 * @property {number} UNKNOWN=0 UNKNOWN value
 * @property {number} HEARTBEAT_REQ=1 HEARTBEAT_REQ value
 * @property {number} HEARTBEAT_RESP=2 HEARTBEAT_RESP value
 * @property {number} AUTH_REQ=3 AUTH_REQ value
 * @property {number} AUTH_RESP=4 AUTH_RESP value
 * @property {number} CLOSE=5 CLOSE value
 * @property {number} ACK=8 ACK value
 * @property {number} ACK_RESP=9 ACK_RESP value
 * @property {number} TEXT=100 TEXT value
 * @property {number} IMAGE=101 IMAGE value
 * @property {number} VOICE=102 VOICE value
 * @property {number} VIDEO=103 VIDEO value
 * @property {number} FILE=104 FILE value
 * @property {number} LOCATION=105 LOCATION value
 * @property {number} CUSTOM=106 CUSTOM value
 * @property {number} SYSTEM_NOTIFY=200 SYSTEM_NOTIFY value
 * @property {number} READ_RECEIPT=201 READ_RECEIPT value
 * @property {number} RECALL=202 RECALL value
 * @property {number} TYPING=203 TYPING value
 * @property {number} BADGE_UPDATE=204 BADGE_UPDATE value
 * @property {number} QUOTE_REPLY=205 QUOTE_REPLY value
 * @property {number} CALL_SIGNAL=206 CALL_SIGNAL value
 * @property {number} WORKFLOW_NOTIFY=207 WORKFLOW_NOTIFY value
 * @property {number} TODO_REMINDER=208 TODO_REMINDER value
 */
export const MessageType = $root.MessageType = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "UNKNOWN"] = 0;
    values[valuesById[1] = "HEARTBEAT_REQ"] = 1;
    values[valuesById[2] = "HEARTBEAT_RESP"] = 2;
    values[valuesById[3] = "AUTH_REQ"] = 3;
    values[valuesById[4] = "AUTH_RESP"] = 4;
    values[valuesById[5] = "CLOSE"] = 5;
    values[valuesById[8] = "ACK"] = 8;
    values[valuesById[9] = "ACK_RESP"] = 9;
    values[valuesById[100] = "TEXT"] = 100;
    values[valuesById[101] = "IMAGE"] = 101;
    values[valuesById[102] = "VOICE"] = 102;
    values[valuesById[103] = "VIDEO"] = 103;
    values[valuesById[104] = "FILE"] = 104;
    values[valuesById[105] = "LOCATION"] = 105;
    values[valuesById[106] = "CUSTOM"] = 106;
    values[valuesById[200] = "SYSTEM_NOTIFY"] = 200;
    values[valuesById[201] = "READ_RECEIPT"] = 201;
    values[valuesById[202] = "RECALL"] = 202;
    values[valuesById[203] = "TYPING"] = 203;
    values[valuesById[204] = "BADGE_UPDATE"] = 204;
    values[valuesById[205] = "QUOTE_REPLY"] = 205;
    values[valuesById[206] = "CALL_SIGNAL"] = 206;
    values[valuesById[207] = "WORKFLOW_NOTIFY"] = 207;
    values[valuesById[208] = "TODO_REMINDER"] = 208;
    return values;
})();

export const AuthRequest = $root.AuthRequest = (() => {

    /**
     * Properties of an AuthRequest.
     * @exports IAuthRequest
     * @interface IAuthRequest
     * @property {string|null} [accessToken] AuthRequest accessToken
     * @property {number|null} [deviceType] AuthRequest deviceType
     * @property {string|null} [deviceId] AuthRequest deviceId
     * @property {string|null} [clientVersion] AuthRequest clientVersion
     */

    /**
     * Constructs a new AuthRequest.
     * @exports AuthRequest
     * @classdesc Represents an AuthRequest.
     * @implements IAuthRequest
     * @constructor
     * @param {IAuthRequest=} [properties] Properties to set
     */
    function AuthRequest(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AuthRequest accessToken.
     * @member {string} accessToken
     * @memberof AuthRequest
     * @instance
     */
    AuthRequest.prototype.accessToken = "";

    /**
     * AuthRequest deviceType.
     * @member {number} deviceType
     * @memberof AuthRequest
     * @instance
     */
    AuthRequest.prototype.deviceType = 0;

    /**
     * AuthRequest deviceId.
     * @member {string} deviceId
     * @memberof AuthRequest
     * @instance
     */
    AuthRequest.prototype.deviceId = "";

    /**
     * AuthRequest clientVersion.
     * @member {string} clientVersion
     * @memberof AuthRequest
     * @instance
     */
    AuthRequest.prototype.clientVersion = "";

    /**
     * Creates a new AuthRequest instance using the specified properties.
     * @function create
     * @memberof AuthRequest
     * @static
     * @param {IAuthRequest=} [properties] Properties to set
     * @returns {AuthRequest} AuthRequest instance
     */
    AuthRequest.create = function create(properties) {
        return new AuthRequest(properties);
    };

    /**
     * Encodes the specified AuthRequest message. Does not implicitly {@link AuthRequest.verify|verify} messages.
     * @function encode
     * @memberof AuthRequest
     * @static
     * @param {IAuthRequest} message AuthRequest message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AuthRequest.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.accessToken != null && Object.hasOwnProperty.call(message, "accessToken"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.accessToken);
        if (message.deviceType != null && Object.hasOwnProperty.call(message, "deviceType"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.deviceType);
        if (message.deviceId != null && Object.hasOwnProperty.call(message, "deviceId"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.deviceId);
        if (message.clientVersion != null && Object.hasOwnProperty.call(message, "clientVersion"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.clientVersion);
        return writer;
    };

    /**
     * Encodes the specified AuthRequest message, length delimited. Does not implicitly {@link AuthRequest.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AuthRequest
     * @static
     * @param {IAuthRequest} message AuthRequest message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AuthRequest.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AuthRequest message from the specified reader or buffer.
     * @function decode
     * @memberof AuthRequest
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AuthRequest} AuthRequest
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AuthRequest.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AuthRequest();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.accessToken = reader.string();
                    break;
                }
            case 2: {
                    message.deviceType = reader.int32();
                    break;
                }
            case 3: {
                    message.deviceId = reader.string();
                    break;
                }
            case 4: {
                    message.clientVersion = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AuthRequest message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AuthRequest
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AuthRequest} AuthRequest
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AuthRequest.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AuthRequest message.
     * @function verify
     * @memberof AuthRequest
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AuthRequest.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.accessToken != null && message.hasOwnProperty("accessToken"))
            if (!$util.isString(message.accessToken))
                return "accessToken: string expected";
        if (message.deviceType != null && message.hasOwnProperty("deviceType"))
            if (!$util.isInteger(message.deviceType))
                return "deviceType: integer expected";
        if (message.deviceId != null && message.hasOwnProperty("deviceId"))
            if (!$util.isString(message.deviceId))
                return "deviceId: string expected";
        if (message.clientVersion != null && message.hasOwnProperty("clientVersion"))
            if (!$util.isString(message.clientVersion))
                return "clientVersion: string expected";
        return null;
    };

    /**
     * Creates an AuthRequest message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AuthRequest
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AuthRequest} AuthRequest
     */
    AuthRequest.fromObject = function fromObject(object) {
        if (object instanceof $root.AuthRequest)
            return object;
        let message = new $root.AuthRequest();
        if (object.accessToken != null)
            message.accessToken = String(object.accessToken);
        if (object.deviceType != null)
            message.deviceType = object.deviceType | 0;
        if (object.deviceId != null)
            message.deviceId = String(object.deviceId);
        if (object.clientVersion != null)
            message.clientVersion = String(object.clientVersion);
        return message;
    };

    /**
     * Creates a plain object from an AuthRequest message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AuthRequest
     * @static
     * @param {AuthRequest} message AuthRequest
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AuthRequest.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.accessToken = "";
            object.deviceType = 0;
            object.deviceId = "";
            object.clientVersion = "";
        }
        if (message.accessToken != null && message.hasOwnProperty("accessToken"))
            object.accessToken = message.accessToken;
        if (message.deviceType != null && message.hasOwnProperty("deviceType"))
            object.deviceType = message.deviceType;
        if (message.deviceId != null && message.hasOwnProperty("deviceId"))
            object.deviceId = message.deviceId;
        if (message.clientVersion != null && message.hasOwnProperty("clientVersion"))
            object.clientVersion = message.clientVersion;
        return object;
    };

    /**
     * Converts this AuthRequest to JSON.
     * @function toJSON
     * @memberof AuthRequest
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AuthRequest.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AuthRequest
     * @function getTypeUrl
     * @memberof AuthRequest
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AuthRequest.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AuthRequest";
    };

    return AuthRequest;
})();

export const AuthResponse = $root.AuthResponse = (() => {

    /**
     * Properties of an AuthResponse.
     * @exports IAuthResponse
     * @interface IAuthResponse
     * @property {boolean|null} [success] AuthResponse success
     * @property {number|null} [code] AuthResponse code
     * @property {string|null} [message] AuthResponse message
     * @property {number|Long|null} [userId] AuthResponse userId
     * @property {number|Long|null} [tenantId] AuthResponse tenantId
     */

    /**
     * Constructs a new AuthResponse.
     * @exports AuthResponse
     * @classdesc Represents an AuthResponse.
     * @implements IAuthResponse
     * @constructor
     * @param {IAuthResponse=} [properties] Properties to set
     */
    function AuthResponse(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AuthResponse success.
     * @member {boolean} success
     * @memberof AuthResponse
     * @instance
     */
    AuthResponse.prototype.success = false;

    /**
     * AuthResponse code.
     * @member {number} code
     * @memberof AuthResponse
     * @instance
     */
    AuthResponse.prototype.code = 0;

    /**
     * AuthResponse message.
     * @member {string} message
     * @memberof AuthResponse
     * @instance
     */
    AuthResponse.prototype.message = "";

    /**
     * AuthResponse userId.
     * @member {number|Long} userId
     * @memberof AuthResponse
     * @instance
     */
    AuthResponse.prototype.userId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * AuthResponse tenantId.
     * @member {number|Long} tenantId
     * @memberof AuthResponse
     * @instance
     */
    AuthResponse.prototype.tenantId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new AuthResponse instance using the specified properties.
     * @function create
     * @memberof AuthResponse
     * @static
     * @param {IAuthResponse=} [properties] Properties to set
     * @returns {AuthResponse} AuthResponse instance
     */
    AuthResponse.create = function create(properties) {
        return new AuthResponse(properties);
    };

    /**
     * Encodes the specified AuthResponse message. Does not implicitly {@link AuthResponse.verify|verify} messages.
     * @function encode
     * @memberof AuthResponse
     * @static
     * @param {IAuthResponse} message AuthResponse message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AuthResponse.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.success != null && Object.hasOwnProperty.call(message, "success"))
            writer.uint32(/* id 1, wireType 0 =*/8).bool(message.success);
        if (message.code != null && Object.hasOwnProperty.call(message, "code"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.code);
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.message);
        if (message.userId != null && Object.hasOwnProperty.call(message, "userId"))
            writer.uint32(/* id 4, wireType 0 =*/32).int64(message.userId);
        if (message.tenantId != null && Object.hasOwnProperty.call(message, "tenantId"))
            writer.uint32(/* id 5, wireType 0 =*/40).int64(message.tenantId);
        return writer;
    };

    /**
     * Encodes the specified AuthResponse message, length delimited. Does not implicitly {@link AuthResponse.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AuthResponse
     * @static
     * @param {IAuthResponse} message AuthResponse message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AuthResponse.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AuthResponse message from the specified reader or buffer.
     * @function decode
     * @memberof AuthResponse
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AuthResponse} AuthResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AuthResponse.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AuthResponse();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.success = reader.bool();
                    break;
                }
            case 2: {
                    message.code = reader.int32();
                    break;
                }
            case 3: {
                    message.message = reader.string();
                    break;
                }
            case 4: {
                    message.userId = reader.int64();
                    break;
                }
            case 5: {
                    message.tenantId = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AuthResponse message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AuthResponse
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AuthResponse} AuthResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AuthResponse.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AuthResponse message.
     * @function verify
     * @memberof AuthResponse
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AuthResponse.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.success != null && message.hasOwnProperty("success"))
            if (typeof message.success !== "boolean")
                return "success: boolean expected";
        if (message.code != null && message.hasOwnProperty("code"))
            if (!$util.isInteger(message.code))
                return "code: integer expected";
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        if (message.userId != null && message.hasOwnProperty("userId"))
            if (!$util.isInteger(message.userId) && !(message.userId && $util.isInteger(message.userId.low) && $util.isInteger(message.userId.high)))
                return "userId: integer|Long expected";
        if (message.tenantId != null && message.hasOwnProperty("tenantId"))
            if (!$util.isInteger(message.tenantId) && !(message.tenantId && $util.isInteger(message.tenantId.low) && $util.isInteger(message.tenantId.high)))
                return "tenantId: integer|Long expected";
        return null;
    };

    /**
     * Creates an AuthResponse message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AuthResponse
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AuthResponse} AuthResponse
     */
    AuthResponse.fromObject = function fromObject(object) {
        if (object instanceof $root.AuthResponse)
            return object;
        let message = new $root.AuthResponse();
        if (object.success != null)
            message.success = Boolean(object.success);
        if (object.code != null)
            message.code = object.code | 0;
        if (object.message != null)
            message.message = String(object.message);
        if (object.userId != null)
            if ($util.Long)
                (message.userId = $util.Long.fromValue(object.userId)).unsigned = false;
            else if (typeof object.userId === "string")
                message.userId = parseInt(object.userId, 10);
            else if (typeof object.userId === "number")
                message.userId = object.userId;
            else if (typeof object.userId === "object")
                message.userId = new $util.LongBits(object.userId.low >>> 0, object.userId.high >>> 0).toNumber();
        if (object.tenantId != null)
            if ($util.Long)
                (message.tenantId = $util.Long.fromValue(object.tenantId)).unsigned = false;
            else if (typeof object.tenantId === "string")
                message.tenantId = parseInt(object.tenantId, 10);
            else if (typeof object.tenantId === "number")
                message.tenantId = object.tenantId;
            else if (typeof object.tenantId === "object")
                message.tenantId = new $util.LongBits(object.tenantId.low >>> 0, object.tenantId.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from an AuthResponse message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AuthResponse
     * @static
     * @param {AuthResponse} message AuthResponse
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AuthResponse.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.success = false;
            object.code = 0;
            object.message = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.userId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.userId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.tenantId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.tenantId = options.longs === String ? "0" : 0;
        }
        if (message.success != null && message.hasOwnProperty("success"))
            object.success = message.success;
        if (message.code != null && message.hasOwnProperty("code"))
            object.code = message.code;
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        if (message.userId != null && message.hasOwnProperty("userId"))
            if (typeof message.userId === "number")
                object.userId = options.longs === String ? String(message.userId) : message.userId;
            else
                object.userId = options.longs === String ? $util.Long.prototype.toString.call(message.userId) : options.longs === Number ? new $util.LongBits(message.userId.low >>> 0, message.userId.high >>> 0).toNumber() : message.userId;
        if (message.tenantId != null && message.hasOwnProperty("tenantId"))
            if (typeof message.tenantId === "number")
                object.tenantId = options.longs === String ? String(message.tenantId) : message.tenantId;
            else
                object.tenantId = options.longs === String ? $util.Long.prototype.toString.call(message.tenantId) : options.longs === Number ? new $util.LongBits(message.tenantId.low >>> 0, message.tenantId.high >>> 0).toNumber() : message.tenantId;
        return object;
    };

    /**
     * Converts this AuthResponse to JSON.
     * @function toJSON
     * @memberof AuthResponse
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AuthResponse.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AuthResponse
     * @function getTypeUrl
     * @memberof AuthResponse
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AuthResponse.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AuthResponse";
    };

    return AuthResponse;
})();

export const AckMessage = $root.AckMessage = (() => {

    /**
     * Properties of an AckMessage.
     * @exports IAckMessage
     * @interface IAckMessage
     * @property {number|Long|null} [messageId] AckMessage messageId
     * @property {number|Long|null} [chatId] AckMessage chatId
     * @property {number|Long|null} [sequence] AckMessage sequence
     * @property {string|null} [ackType] AckMessage ackType
     * @property {number|Long|null} [clientReceivedAt] AckMessage clientReceivedAt
     * @property {number|Long|null} [originalTimestamp] AckMessage originalTimestamp
     */

    /**
     * Constructs a new AckMessage.
     * @exports AckMessage
     * @classdesc Represents an AckMessage.
     * @implements IAckMessage
     * @constructor
     * @param {IAckMessage=} [properties] Properties to set
     */
    function AckMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AckMessage messageId.
     * @member {number|Long} messageId
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.messageId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * AckMessage chatId.
     * @member {number|Long} chatId
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.chatId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * AckMessage sequence.
     * @member {number|Long} sequence
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.sequence = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * AckMessage ackType.
     * @member {string} ackType
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.ackType = "";

    /**
     * AckMessage clientReceivedAt.
     * @member {number|Long} clientReceivedAt
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.clientReceivedAt = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * AckMessage originalTimestamp.
     * @member {number|Long} originalTimestamp
     * @memberof AckMessage
     * @instance
     */
    AckMessage.prototype.originalTimestamp = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new AckMessage instance using the specified properties.
     * @function create
     * @memberof AckMessage
     * @static
     * @param {IAckMessage=} [properties] Properties to set
     * @returns {AckMessage} AckMessage instance
     */
    AckMessage.create = function create(properties) {
        return new AckMessage(properties);
    };

    /**
     * Encodes the specified AckMessage message. Does not implicitly {@link AckMessage.verify|verify} messages.
     * @function encode
     * @memberof AckMessage
     * @static
     * @param {IAckMessage} message AckMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AckMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.messageId != null && Object.hasOwnProperty.call(message, "messageId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.messageId);
        if (message.chatId != null && Object.hasOwnProperty.call(message, "chatId"))
            writer.uint32(/* id 2, wireType 0 =*/16).int64(message.chatId);
        if (message.sequence != null && Object.hasOwnProperty.call(message, "sequence"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.sequence);
        if (message.ackType != null && Object.hasOwnProperty.call(message, "ackType"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.ackType);
        if (message.clientReceivedAt != null && Object.hasOwnProperty.call(message, "clientReceivedAt"))
            writer.uint32(/* id 5, wireType 0 =*/40).int64(message.clientReceivedAt);
        if (message.originalTimestamp != null && Object.hasOwnProperty.call(message, "originalTimestamp"))
            writer.uint32(/* id 6, wireType 0 =*/48).int64(message.originalTimestamp);
        return writer;
    };

    /**
     * Encodes the specified AckMessage message, length delimited. Does not implicitly {@link AckMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AckMessage
     * @static
     * @param {IAckMessage} message AckMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AckMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AckMessage message from the specified reader or buffer.
     * @function decode
     * @memberof AckMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AckMessage} AckMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AckMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AckMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.messageId = reader.int64();
                    break;
                }
            case 2: {
                    message.chatId = reader.int64();
                    break;
                }
            case 3: {
                    message.sequence = reader.int64();
                    break;
                }
            case 4: {
                    message.ackType = reader.string();
                    break;
                }
            case 5: {
                    message.clientReceivedAt = reader.int64();
                    break;
                }
            case 6: {
                    message.originalTimestamp = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AckMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AckMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AckMessage} AckMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AckMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AckMessage message.
     * @function verify
     * @memberof AckMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AckMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (!$util.isInteger(message.messageId) && !(message.messageId && $util.isInteger(message.messageId.low) && $util.isInteger(message.messageId.high)))
                return "messageId: integer|Long expected";
        if (message.chatId != null && message.hasOwnProperty("chatId"))
            if (!$util.isInteger(message.chatId) && !(message.chatId && $util.isInteger(message.chatId.low) && $util.isInteger(message.chatId.high)))
                return "chatId: integer|Long expected";
        if (message.sequence != null && message.hasOwnProperty("sequence"))
            if (!$util.isInteger(message.sequence) && !(message.sequence && $util.isInteger(message.sequence.low) && $util.isInteger(message.sequence.high)))
                return "sequence: integer|Long expected";
        if (message.ackType != null && message.hasOwnProperty("ackType"))
            if (!$util.isString(message.ackType))
                return "ackType: string expected";
        if (message.clientReceivedAt != null && message.hasOwnProperty("clientReceivedAt"))
            if (!$util.isInteger(message.clientReceivedAt) && !(message.clientReceivedAt && $util.isInteger(message.clientReceivedAt.low) && $util.isInteger(message.clientReceivedAt.high)))
                return "clientReceivedAt: integer|Long expected";
        if (message.originalTimestamp != null && message.hasOwnProperty("originalTimestamp"))
            if (!$util.isInteger(message.originalTimestamp) && !(message.originalTimestamp && $util.isInteger(message.originalTimestamp.low) && $util.isInteger(message.originalTimestamp.high)))
                return "originalTimestamp: integer|Long expected";
        return null;
    };

    /**
     * Creates an AckMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AckMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AckMessage} AckMessage
     */
    AckMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.AckMessage)
            return object;
        let message = new $root.AckMessage();
        if (object.messageId != null)
            if ($util.Long)
                (message.messageId = $util.Long.fromValue(object.messageId)).unsigned = false;
            else if (typeof object.messageId === "string")
                message.messageId = parseInt(object.messageId, 10);
            else if (typeof object.messageId === "number")
                message.messageId = object.messageId;
            else if (typeof object.messageId === "object")
                message.messageId = new $util.LongBits(object.messageId.low >>> 0, object.messageId.high >>> 0).toNumber();
        if (object.chatId != null)
            if ($util.Long)
                (message.chatId = $util.Long.fromValue(object.chatId)).unsigned = false;
            else if (typeof object.chatId === "string")
                message.chatId = parseInt(object.chatId, 10);
            else if (typeof object.chatId === "number")
                message.chatId = object.chatId;
            else if (typeof object.chatId === "object")
                message.chatId = new $util.LongBits(object.chatId.low >>> 0, object.chatId.high >>> 0).toNumber();
        if (object.sequence != null)
            if ($util.Long)
                (message.sequence = $util.Long.fromValue(object.sequence)).unsigned = false;
            else if (typeof object.sequence === "string")
                message.sequence = parseInt(object.sequence, 10);
            else if (typeof object.sequence === "number")
                message.sequence = object.sequence;
            else if (typeof object.sequence === "object")
                message.sequence = new $util.LongBits(object.sequence.low >>> 0, object.sequence.high >>> 0).toNumber();
        if (object.ackType != null)
            message.ackType = String(object.ackType);
        if (object.clientReceivedAt != null)
            if ($util.Long)
                (message.clientReceivedAt = $util.Long.fromValue(object.clientReceivedAt)).unsigned = false;
            else if (typeof object.clientReceivedAt === "string")
                message.clientReceivedAt = parseInt(object.clientReceivedAt, 10);
            else if (typeof object.clientReceivedAt === "number")
                message.clientReceivedAt = object.clientReceivedAt;
            else if (typeof object.clientReceivedAt === "object")
                message.clientReceivedAt = new $util.LongBits(object.clientReceivedAt.low >>> 0, object.clientReceivedAt.high >>> 0).toNumber();
        if (object.originalTimestamp != null)
            if ($util.Long)
                (message.originalTimestamp = $util.Long.fromValue(object.originalTimestamp)).unsigned = false;
            else if (typeof object.originalTimestamp === "string")
                message.originalTimestamp = parseInt(object.originalTimestamp, 10);
            else if (typeof object.originalTimestamp === "number")
                message.originalTimestamp = object.originalTimestamp;
            else if (typeof object.originalTimestamp === "object")
                message.originalTimestamp = new $util.LongBits(object.originalTimestamp.low >>> 0, object.originalTimestamp.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from an AckMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AckMessage
     * @static
     * @param {AckMessage} message AckMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AckMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.messageId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.messageId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.chatId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.chatId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.sequence = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.sequence = options.longs === String ? "0" : 0;
            object.ackType = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.clientReceivedAt = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.clientReceivedAt = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.originalTimestamp = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.originalTimestamp = options.longs === String ? "0" : 0;
        }
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (typeof message.messageId === "number")
                object.messageId = options.longs === String ? String(message.messageId) : message.messageId;
            else
                object.messageId = options.longs === String ? $util.Long.prototype.toString.call(message.messageId) : options.longs === Number ? new $util.LongBits(message.messageId.low >>> 0, message.messageId.high >>> 0).toNumber() : message.messageId;
        if (message.chatId != null && message.hasOwnProperty("chatId"))
            if (typeof message.chatId === "number")
                object.chatId = options.longs === String ? String(message.chatId) : message.chatId;
            else
                object.chatId = options.longs === String ? $util.Long.prototype.toString.call(message.chatId) : options.longs === Number ? new $util.LongBits(message.chatId.low >>> 0, message.chatId.high >>> 0).toNumber() : message.chatId;
        if (message.sequence != null && message.hasOwnProperty("sequence"))
            if (typeof message.sequence === "number")
                object.sequence = options.longs === String ? String(message.sequence) : message.sequence;
            else
                object.sequence = options.longs === String ? $util.Long.prototype.toString.call(message.sequence) : options.longs === Number ? new $util.LongBits(message.sequence.low >>> 0, message.sequence.high >>> 0).toNumber() : message.sequence;
        if (message.ackType != null && message.hasOwnProperty("ackType"))
            object.ackType = message.ackType;
        if (message.clientReceivedAt != null && message.hasOwnProperty("clientReceivedAt"))
            if (typeof message.clientReceivedAt === "number")
                object.clientReceivedAt = options.longs === String ? String(message.clientReceivedAt) : message.clientReceivedAt;
            else
                object.clientReceivedAt = options.longs === String ? $util.Long.prototype.toString.call(message.clientReceivedAt) : options.longs === Number ? new $util.LongBits(message.clientReceivedAt.low >>> 0, message.clientReceivedAt.high >>> 0).toNumber() : message.clientReceivedAt;
        if (message.originalTimestamp != null && message.hasOwnProperty("originalTimestamp"))
            if (typeof message.originalTimestamp === "number")
                object.originalTimestamp = options.longs === String ? String(message.originalTimestamp) : message.originalTimestamp;
            else
                object.originalTimestamp = options.longs === String ? $util.Long.prototype.toString.call(message.originalTimestamp) : options.longs === Number ? new $util.LongBits(message.originalTimestamp.low >>> 0, message.originalTimestamp.high >>> 0).toNumber() : message.originalTimestamp;
        return object;
    };

    /**
     * Converts this AckMessage to JSON.
     * @function toJSON
     * @memberof AckMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AckMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AckMessage
     * @function getTypeUrl
     * @memberof AckMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AckMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AckMessage";
    };

    return AckMessage;
})();

export const AckResponse = $root.AckResponse = (() => {

    /**
     * Properties of an AckResponse.
     * @exports IAckResponse
     * @interface IAckResponse
     * @property {boolean|null} [success] AckResponse success
     * @property {number|null} [code] AckResponse code
     * @property {string|null} [message] AckResponse message
     */

    /**
     * Constructs a new AckResponse.
     * @exports AckResponse
     * @classdesc Represents an AckResponse.
     * @implements IAckResponse
     * @constructor
     * @param {IAckResponse=} [properties] Properties to set
     */
    function AckResponse(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AckResponse success.
     * @member {boolean} success
     * @memberof AckResponse
     * @instance
     */
    AckResponse.prototype.success = false;

    /**
     * AckResponse code.
     * @member {number} code
     * @memberof AckResponse
     * @instance
     */
    AckResponse.prototype.code = 0;

    /**
     * AckResponse message.
     * @member {string} message
     * @memberof AckResponse
     * @instance
     */
    AckResponse.prototype.message = "";

    /**
     * Creates a new AckResponse instance using the specified properties.
     * @function create
     * @memberof AckResponse
     * @static
     * @param {IAckResponse=} [properties] Properties to set
     * @returns {AckResponse} AckResponse instance
     */
    AckResponse.create = function create(properties) {
        return new AckResponse(properties);
    };

    /**
     * Encodes the specified AckResponse message. Does not implicitly {@link AckResponse.verify|verify} messages.
     * @function encode
     * @memberof AckResponse
     * @static
     * @param {IAckResponse} message AckResponse message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AckResponse.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.success != null && Object.hasOwnProperty.call(message, "success"))
            writer.uint32(/* id 1, wireType 0 =*/8).bool(message.success);
        if (message.code != null && Object.hasOwnProperty.call(message, "code"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.code);
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.message);
        return writer;
    };

    /**
     * Encodes the specified AckResponse message, length delimited. Does not implicitly {@link AckResponse.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AckResponse
     * @static
     * @param {IAckResponse} message AckResponse message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AckResponse.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AckResponse message from the specified reader or buffer.
     * @function decode
     * @memberof AckResponse
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AckResponse} AckResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AckResponse.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AckResponse();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.success = reader.bool();
                    break;
                }
            case 2: {
                    message.code = reader.int32();
                    break;
                }
            case 3: {
                    message.message = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AckResponse message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AckResponse
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AckResponse} AckResponse
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AckResponse.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AckResponse message.
     * @function verify
     * @memberof AckResponse
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AckResponse.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.success != null && message.hasOwnProperty("success"))
            if (typeof message.success !== "boolean")
                return "success: boolean expected";
        if (message.code != null && message.hasOwnProperty("code"))
            if (!$util.isInteger(message.code))
                return "code: integer expected";
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        return null;
    };

    /**
     * Creates an AckResponse message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AckResponse
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AckResponse} AckResponse
     */
    AckResponse.fromObject = function fromObject(object) {
        if (object instanceof $root.AckResponse)
            return object;
        let message = new $root.AckResponse();
        if (object.success != null)
            message.success = Boolean(object.success);
        if (object.code != null)
            message.code = object.code | 0;
        if (object.message != null)
            message.message = String(object.message);
        return message;
    };

    /**
     * Creates a plain object from an AckResponse message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AckResponse
     * @static
     * @param {AckResponse} message AckResponse
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AckResponse.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.success = false;
            object.code = 0;
            object.message = "";
        }
        if (message.success != null && message.hasOwnProperty("success"))
            object.success = message.success;
        if (message.code != null && message.hasOwnProperty("code"))
            object.code = message.code;
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        return object;
    };

    /**
     * Converts this AckResponse to JSON.
     * @function toJSON
     * @memberof AckResponse
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AckResponse.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AckResponse
     * @function getTypeUrl
     * @memberof AckResponse
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AckResponse.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AckResponse";
    };

    return AckResponse;
})();

export const MentionUser = $root.MentionUser = (() => {

    /**
     * Properties of a MentionUser.
     * @exports IMentionUser
     * @interface IMentionUser
     * @property {number|Long|null} [userId] MentionUser userId
     * @property {string|null} [nickname] MentionUser nickname
     * @property {number|null} [startIndex] MentionUser startIndex
     * @property {number|null} [endIndex] MentionUser endIndex
     */

    /**
     * Constructs a new MentionUser.
     * @exports MentionUser
     * @classdesc Represents a MentionUser.
     * @implements IMentionUser
     * @constructor
     * @param {IMentionUser=} [properties] Properties to set
     */
    function MentionUser(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * MentionUser userId.
     * @member {number|Long} userId
     * @memberof MentionUser
     * @instance
     */
    MentionUser.prototype.userId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * MentionUser nickname.
     * @member {string} nickname
     * @memberof MentionUser
     * @instance
     */
    MentionUser.prototype.nickname = "";

    /**
     * MentionUser startIndex.
     * @member {number} startIndex
     * @memberof MentionUser
     * @instance
     */
    MentionUser.prototype.startIndex = 0;

    /**
     * MentionUser endIndex.
     * @member {number} endIndex
     * @memberof MentionUser
     * @instance
     */
    MentionUser.prototype.endIndex = 0;

    /**
     * Creates a new MentionUser instance using the specified properties.
     * @function create
     * @memberof MentionUser
     * @static
     * @param {IMentionUser=} [properties] Properties to set
     * @returns {MentionUser} MentionUser instance
     */
    MentionUser.create = function create(properties) {
        return new MentionUser(properties);
    };

    /**
     * Encodes the specified MentionUser message. Does not implicitly {@link MentionUser.verify|verify} messages.
     * @function encode
     * @memberof MentionUser
     * @static
     * @param {IMentionUser} message MentionUser message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MentionUser.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.userId != null && Object.hasOwnProperty.call(message, "userId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.userId);
        if (message.nickname != null && Object.hasOwnProperty.call(message, "nickname"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.nickname);
        if (message.startIndex != null && Object.hasOwnProperty.call(message, "startIndex"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.startIndex);
        if (message.endIndex != null && Object.hasOwnProperty.call(message, "endIndex"))
            writer.uint32(/* id 4, wireType 0 =*/32).int32(message.endIndex);
        return writer;
    };

    /**
     * Encodes the specified MentionUser message, length delimited. Does not implicitly {@link MentionUser.verify|verify} messages.
     * @function encodeDelimited
     * @memberof MentionUser
     * @static
     * @param {IMentionUser} message MentionUser message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MentionUser.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a MentionUser message from the specified reader or buffer.
     * @function decode
     * @memberof MentionUser
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {MentionUser} MentionUser
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MentionUser.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.MentionUser();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.userId = reader.int64();
                    break;
                }
            case 2: {
                    message.nickname = reader.string();
                    break;
                }
            case 3: {
                    message.startIndex = reader.int32();
                    break;
                }
            case 4: {
                    message.endIndex = reader.int32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a MentionUser message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof MentionUser
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {MentionUser} MentionUser
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MentionUser.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a MentionUser message.
     * @function verify
     * @memberof MentionUser
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    MentionUser.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.userId != null && message.hasOwnProperty("userId"))
            if (!$util.isInteger(message.userId) && !(message.userId && $util.isInteger(message.userId.low) && $util.isInteger(message.userId.high)))
                return "userId: integer|Long expected";
        if (message.nickname != null && message.hasOwnProperty("nickname"))
            if (!$util.isString(message.nickname))
                return "nickname: string expected";
        if (message.startIndex != null && message.hasOwnProperty("startIndex"))
            if (!$util.isInteger(message.startIndex))
                return "startIndex: integer expected";
        if (message.endIndex != null && message.hasOwnProperty("endIndex"))
            if (!$util.isInteger(message.endIndex))
                return "endIndex: integer expected";
        return null;
    };

    /**
     * Creates a MentionUser message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof MentionUser
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {MentionUser} MentionUser
     */
    MentionUser.fromObject = function fromObject(object) {
        if (object instanceof $root.MentionUser)
            return object;
        let message = new $root.MentionUser();
        if (object.userId != null)
            if ($util.Long)
                (message.userId = $util.Long.fromValue(object.userId)).unsigned = false;
            else if (typeof object.userId === "string")
                message.userId = parseInt(object.userId, 10);
            else if (typeof object.userId === "number")
                message.userId = object.userId;
            else if (typeof object.userId === "object")
                message.userId = new $util.LongBits(object.userId.low >>> 0, object.userId.high >>> 0).toNumber();
        if (object.nickname != null)
            message.nickname = String(object.nickname);
        if (object.startIndex != null)
            message.startIndex = object.startIndex | 0;
        if (object.endIndex != null)
            message.endIndex = object.endIndex | 0;
        return message;
    };

    /**
     * Creates a plain object from a MentionUser message. Also converts values to other types if specified.
     * @function toObject
     * @memberof MentionUser
     * @static
     * @param {MentionUser} message MentionUser
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    MentionUser.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.userId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.userId = options.longs === String ? "0" : 0;
            object.nickname = "";
            object.startIndex = 0;
            object.endIndex = 0;
        }
        if (message.userId != null && message.hasOwnProperty("userId"))
            if (typeof message.userId === "number")
                object.userId = options.longs === String ? String(message.userId) : message.userId;
            else
                object.userId = options.longs === String ? $util.Long.prototype.toString.call(message.userId) : options.longs === Number ? new $util.LongBits(message.userId.low >>> 0, message.userId.high >>> 0).toNumber() : message.userId;
        if (message.nickname != null && message.hasOwnProperty("nickname"))
            object.nickname = message.nickname;
        if (message.startIndex != null && message.hasOwnProperty("startIndex"))
            object.startIndex = message.startIndex;
        if (message.endIndex != null && message.hasOwnProperty("endIndex"))
            object.endIndex = message.endIndex;
        return object;
    };

    /**
     * Converts this MentionUser to JSON.
     * @function toJSON
     * @memberof MentionUser
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    MentionUser.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for MentionUser
     * @function getTypeUrl
     * @memberof MentionUser
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    MentionUser.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/MentionUser";
    };

    return MentionUser;
})();

export const TextMessage = $root.TextMessage = (() => {

    /**
     * Properties of a TextMessage.
     * @exports ITextMessage
     * @interface ITextMessage
     * @property {string|null} [content] TextMessage content
     * @property {Array.<number|Long>|null} [atUserIds] TextMessage atUserIds
     * @property {Array.<IMentionUser>|null} [mentions] TextMessage mentions
     */

    /**
     * Constructs a new TextMessage.
     * @exports TextMessage
     * @classdesc Represents a TextMessage.
     * @implements ITextMessage
     * @constructor
     * @param {ITextMessage=} [properties] Properties to set
     */
    function TextMessage(properties) {
        this.atUserIds = [];
        this.mentions = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * TextMessage content.
     * @member {string} content
     * @memberof TextMessage
     * @instance
     */
    TextMessage.prototype.content = "";

    /**
     * TextMessage atUserIds.
     * @member {Array.<number|Long>} atUserIds
     * @memberof TextMessage
     * @instance
     */
    TextMessage.prototype.atUserIds = $util.emptyArray;

    /**
     * TextMessage mentions.
     * @member {Array.<IMentionUser>} mentions
     * @memberof TextMessage
     * @instance
     */
    TextMessage.prototype.mentions = $util.emptyArray;

    /**
     * Creates a new TextMessage instance using the specified properties.
     * @function create
     * @memberof TextMessage
     * @static
     * @param {ITextMessage=} [properties] Properties to set
     * @returns {TextMessage} TextMessage instance
     */
    TextMessage.create = function create(properties) {
        return new TextMessage(properties);
    };

    /**
     * Encodes the specified TextMessage message. Does not implicitly {@link TextMessage.verify|verify} messages.
     * @function encode
     * @memberof TextMessage
     * @static
     * @param {ITextMessage} message TextMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TextMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.content != null && Object.hasOwnProperty.call(message, "content"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.content);
        if (message.atUserIds != null && message.atUserIds.length) {
            writer.uint32(/* id 2, wireType 2 =*/18).fork();
            for (let i = 0; i < message.atUserIds.length; ++i)
                writer.int64(message.atUserIds[i]);
            writer.ldelim();
        }
        if (message.mentions != null && message.mentions.length)
            for (let i = 0; i < message.mentions.length; ++i)
                $root.MentionUser.encode(message.mentions[i], writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
        return writer;
    };

    /**
     * Encodes the specified TextMessage message, length delimited. Does not implicitly {@link TextMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof TextMessage
     * @static
     * @param {ITextMessage} message TextMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TextMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a TextMessage message from the specified reader or buffer.
     * @function decode
     * @memberof TextMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {TextMessage} TextMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TextMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.TextMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.content = reader.string();
                    break;
                }
            case 2: {
                    if (!(message.atUserIds && message.atUserIds.length))
                        message.atUserIds = [];
                    if ((tag & 7) === 2) {
                        let end2 = reader.uint32() + reader.pos;
                        while (reader.pos < end2)
                            message.atUserIds.push(reader.int64());
                    } else
                        message.atUserIds.push(reader.int64());
                    break;
                }
            case 3: {
                    if (!(message.mentions && message.mentions.length))
                        message.mentions = [];
                    message.mentions.push($root.MentionUser.decode(reader, reader.uint32()));
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a TextMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof TextMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {TextMessage} TextMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TextMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a TextMessage message.
     * @function verify
     * @memberof TextMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    TextMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.content != null && message.hasOwnProperty("content"))
            if (!$util.isString(message.content))
                return "content: string expected";
        if (message.atUserIds != null && message.hasOwnProperty("atUserIds")) {
            if (!Array.isArray(message.atUserIds))
                return "atUserIds: array expected";
            for (let i = 0; i < message.atUserIds.length; ++i)
                if (!$util.isInteger(message.atUserIds[i]) && !(message.atUserIds[i] && $util.isInteger(message.atUserIds[i].low) && $util.isInteger(message.atUserIds[i].high)))
                    return "atUserIds: integer|Long[] expected";
        }
        if (message.mentions != null && message.hasOwnProperty("mentions")) {
            if (!Array.isArray(message.mentions))
                return "mentions: array expected";
            for (let i = 0; i < message.mentions.length; ++i) {
                let error = $root.MentionUser.verify(message.mentions[i]);
                if (error)
                    return "mentions." + error;
            }
        }
        return null;
    };

    /**
     * Creates a TextMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof TextMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {TextMessage} TextMessage
     */
    TextMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.TextMessage)
            return object;
        let message = new $root.TextMessage();
        if (object.content != null)
            message.content = String(object.content);
        if (object.atUserIds) {
            if (!Array.isArray(object.atUserIds))
                throw TypeError(".TextMessage.atUserIds: array expected");
            message.atUserIds = [];
            for (let i = 0; i < object.atUserIds.length; ++i)
                if ($util.Long)
                    (message.atUserIds[i] = $util.Long.fromValue(object.atUserIds[i])).unsigned = false;
                else if (typeof object.atUserIds[i] === "string")
                    message.atUserIds[i] = parseInt(object.atUserIds[i], 10);
                else if (typeof object.atUserIds[i] === "number")
                    message.atUserIds[i] = object.atUserIds[i];
                else if (typeof object.atUserIds[i] === "object")
                    message.atUserIds[i] = new $util.LongBits(object.atUserIds[i].low >>> 0, object.atUserIds[i].high >>> 0).toNumber();
        }
        if (object.mentions) {
            if (!Array.isArray(object.mentions))
                throw TypeError(".TextMessage.mentions: array expected");
            message.mentions = [];
            for (let i = 0; i < object.mentions.length; ++i) {
                if (typeof object.mentions[i] !== "object")
                    throw TypeError(".TextMessage.mentions: object expected");
                message.mentions[i] = $root.MentionUser.fromObject(object.mentions[i]);
            }
        }
        return message;
    };

    /**
     * Creates a plain object from a TextMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof TextMessage
     * @static
     * @param {TextMessage} message TextMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    TextMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults) {
            object.atUserIds = [];
            object.mentions = [];
        }
        if (options.defaults)
            object.content = "";
        if (message.content != null && message.hasOwnProperty("content"))
            object.content = message.content;
        if (message.atUserIds && message.atUserIds.length) {
            object.atUserIds = [];
            for (let j = 0; j < message.atUserIds.length; ++j)
                if (typeof message.atUserIds[j] === "number")
                    object.atUserIds[j] = options.longs === String ? String(message.atUserIds[j]) : message.atUserIds[j];
                else
                    object.atUserIds[j] = options.longs === String ? $util.Long.prototype.toString.call(message.atUserIds[j]) : options.longs === Number ? new $util.LongBits(message.atUserIds[j].low >>> 0, message.atUserIds[j].high >>> 0).toNumber() : message.atUserIds[j];
        }
        if (message.mentions && message.mentions.length) {
            object.mentions = [];
            for (let j = 0; j < message.mentions.length; ++j)
                object.mentions[j] = $root.MentionUser.toObject(message.mentions[j], options);
        }
        return object;
    };

    /**
     * Converts this TextMessage to JSON.
     * @function toJSON
     * @memberof TextMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    TextMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for TextMessage
     * @function getTypeUrl
     * @memberof TextMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    TextMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/TextMessage";
    };

    return TextMessage;
})();

export const ImageMessage = $root.ImageMessage = (() => {

    /**
     * Properties of an ImageMessage.
     * @exports IImageMessage
     * @interface IImageMessage
     * @property {string|null} [url] ImageMessage url
     * @property {string|null} [thumbnailUrl] ImageMessage thumbnailUrl
     * @property {number|null} [width] ImageMessage width
     * @property {number|null} [height] ImageMessage height
     * @property {number|Long|null} [size] ImageMessage size
     */

    /**
     * Constructs a new ImageMessage.
     * @exports ImageMessage
     * @classdesc Represents an ImageMessage.
     * @implements IImageMessage
     * @constructor
     * @param {IImageMessage=} [properties] Properties to set
     */
    function ImageMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * ImageMessage url.
     * @member {string} url
     * @memberof ImageMessage
     * @instance
     */
    ImageMessage.prototype.url = "";

    /**
     * ImageMessage thumbnailUrl.
     * @member {string} thumbnailUrl
     * @memberof ImageMessage
     * @instance
     */
    ImageMessage.prototype.thumbnailUrl = "";

    /**
     * ImageMessage width.
     * @member {number} width
     * @memberof ImageMessage
     * @instance
     */
    ImageMessage.prototype.width = 0;

    /**
     * ImageMessage height.
     * @member {number} height
     * @memberof ImageMessage
     * @instance
     */
    ImageMessage.prototype.height = 0;

    /**
     * ImageMessage size.
     * @member {number|Long} size
     * @memberof ImageMessage
     * @instance
     */
    ImageMessage.prototype.size = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new ImageMessage instance using the specified properties.
     * @function create
     * @memberof ImageMessage
     * @static
     * @param {IImageMessage=} [properties] Properties to set
     * @returns {ImageMessage} ImageMessage instance
     */
    ImageMessage.create = function create(properties) {
        return new ImageMessage(properties);
    };

    /**
     * Encodes the specified ImageMessage message. Does not implicitly {@link ImageMessage.verify|verify} messages.
     * @function encode
     * @memberof ImageMessage
     * @static
     * @param {IImageMessage} message ImageMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ImageMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.url != null && Object.hasOwnProperty.call(message, "url"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.url);
        if (message.thumbnailUrl != null && Object.hasOwnProperty.call(message, "thumbnailUrl"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.thumbnailUrl);
        if (message.width != null && Object.hasOwnProperty.call(message, "width"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.width);
        if (message.height != null && Object.hasOwnProperty.call(message, "height"))
            writer.uint32(/* id 4, wireType 0 =*/32).int32(message.height);
        if (message.size != null && Object.hasOwnProperty.call(message, "size"))
            writer.uint32(/* id 5, wireType 0 =*/40).int64(message.size);
        return writer;
    };

    /**
     * Encodes the specified ImageMessage message, length delimited. Does not implicitly {@link ImageMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof ImageMessage
     * @static
     * @param {IImageMessage} message ImageMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ImageMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an ImageMessage message from the specified reader or buffer.
     * @function decode
     * @memberof ImageMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {ImageMessage} ImageMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ImageMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.ImageMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.url = reader.string();
                    break;
                }
            case 2: {
                    message.thumbnailUrl = reader.string();
                    break;
                }
            case 3: {
                    message.width = reader.int32();
                    break;
                }
            case 4: {
                    message.height = reader.int32();
                    break;
                }
            case 5: {
                    message.size = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an ImageMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof ImageMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {ImageMessage} ImageMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ImageMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an ImageMessage message.
     * @function verify
     * @memberof ImageMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    ImageMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.url != null && message.hasOwnProperty("url"))
            if (!$util.isString(message.url))
                return "url: string expected";
        if (message.thumbnailUrl != null && message.hasOwnProperty("thumbnailUrl"))
            if (!$util.isString(message.thumbnailUrl))
                return "thumbnailUrl: string expected";
        if (message.width != null && message.hasOwnProperty("width"))
            if (!$util.isInteger(message.width))
                return "width: integer expected";
        if (message.height != null && message.hasOwnProperty("height"))
            if (!$util.isInteger(message.height))
                return "height: integer expected";
        if (message.size != null && message.hasOwnProperty("size"))
            if (!$util.isInteger(message.size) && !(message.size && $util.isInteger(message.size.low) && $util.isInteger(message.size.high)))
                return "size: integer|Long expected";
        return null;
    };

    /**
     * Creates an ImageMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof ImageMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {ImageMessage} ImageMessage
     */
    ImageMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.ImageMessage)
            return object;
        let message = new $root.ImageMessage();
        if (object.url != null)
            message.url = String(object.url);
        if (object.thumbnailUrl != null)
            message.thumbnailUrl = String(object.thumbnailUrl);
        if (object.width != null)
            message.width = object.width | 0;
        if (object.height != null)
            message.height = object.height | 0;
        if (object.size != null)
            if ($util.Long)
                (message.size = $util.Long.fromValue(object.size)).unsigned = false;
            else if (typeof object.size === "string")
                message.size = parseInt(object.size, 10);
            else if (typeof object.size === "number")
                message.size = object.size;
            else if (typeof object.size === "object")
                message.size = new $util.LongBits(object.size.low >>> 0, object.size.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from an ImageMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof ImageMessage
     * @static
     * @param {ImageMessage} message ImageMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    ImageMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.url = "";
            object.thumbnailUrl = "";
            object.width = 0;
            object.height = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.size = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.size = options.longs === String ? "0" : 0;
        }
        if (message.url != null && message.hasOwnProperty("url"))
            object.url = message.url;
        if (message.thumbnailUrl != null && message.hasOwnProperty("thumbnailUrl"))
            object.thumbnailUrl = message.thumbnailUrl;
        if (message.width != null && message.hasOwnProperty("width"))
            object.width = message.width;
        if (message.height != null && message.hasOwnProperty("height"))
            object.height = message.height;
        if (message.size != null && message.hasOwnProperty("size"))
            if (typeof message.size === "number")
                object.size = options.longs === String ? String(message.size) : message.size;
            else
                object.size = options.longs === String ? $util.Long.prototype.toString.call(message.size) : options.longs === Number ? new $util.LongBits(message.size.low >>> 0, message.size.high >>> 0).toNumber() : message.size;
        return object;
    };

    /**
     * Converts this ImageMessage to JSON.
     * @function toJSON
     * @memberof ImageMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    ImageMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for ImageMessage
     * @function getTypeUrl
     * @memberof ImageMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    ImageMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/ImageMessage";
    };

    return ImageMessage;
})();

export const VoiceMessage = $root.VoiceMessage = (() => {

    /**
     * Properties of a VoiceMessage.
     * @exports IVoiceMessage
     * @interface IVoiceMessage
     * @property {string|null} [url] VoiceMessage url
     * @property {number|null} [duration] VoiceMessage duration
     * @property {number|Long|null} [size] VoiceMessage size
     */

    /**
     * Constructs a new VoiceMessage.
     * @exports VoiceMessage
     * @classdesc Represents a VoiceMessage.
     * @implements IVoiceMessage
     * @constructor
     * @param {IVoiceMessage=} [properties] Properties to set
     */
    function VoiceMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * VoiceMessage url.
     * @member {string} url
     * @memberof VoiceMessage
     * @instance
     */
    VoiceMessage.prototype.url = "";

    /**
     * VoiceMessage duration.
     * @member {number} duration
     * @memberof VoiceMessage
     * @instance
     */
    VoiceMessage.prototype.duration = 0;

    /**
     * VoiceMessage size.
     * @member {number|Long} size
     * @memberof VoiceMessage
     * @instance
     */
    VoiceMessage.prototype.size = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new VoiceMessage instance using the specified properties.
     * @function create
     * @memberof VoiceMessage
     * @static
     * @param {IVoiceMessage=} [properties] Properties to set
     * @returns {VoiceMessage} VoiceMessage instance
     */
    VoiceMessage.create = function create(properties) {
        return new VoiceMessage(properties);
    };

    /**
     * Encodes the specified VoiceMessage message. Does not implicitly {@link VoiceMessage.verify|verify} messages.
     * @function encode
     * @memberof VoiceMessage
     * @static
     * @param {IVoiceMessage} message VoiceMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    VoiceMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.url != null && Object.hasOwnProperty.call(message, "url"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.url);
        if (message.duration != null && Object.hasOwnProperty.call(message, "duration"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.duration);
        if (message.size != null && Object.hasOwnProperty.call(message, "size"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.size);
        return writer;
    };

    /**
     * Encodes the specified VoiceMessage message, length delimited. Does not implicitly {@link VoiceMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof VoiceMessage
     * @static
     * @param {IVoiceMessage} message VoiceMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    VoiceMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a VoiceMessage message from the specified reader or buffer.
     * @function decode
     * @memberof VoiceMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {VoiceMessage} VoiceMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    VoiceMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.VoiceMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.url = reader.string();
                    break;
                }
            case 2: {
                    message.duration = reader.int32();
                    break;
                }
            case 3: {
                    message.size = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a VoiceMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof VoiceMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {VoiceMessage} VoiceMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    VoiceMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a VoiceMessage message.
     * @function verify
     * @memberof VoiceMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    VoiceMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.url != null && message.hasOwnProperty("url"))
            if (!$util.isString(message.url))
                return "url: string expected";
        if (message.duration != null && message.hasOwnProperty("duration"))
            if (!$util.isInteger(message.duration))
                return "duration: integer expected";
        if (message.size != null && message.hasOwnProperty("size"))
            if (!$util.isInteger(message.size) && !(message.size && $util.isInteger(message.size.low) && $util.isInteger(message.size.high)))
                return "size: integer|Long expected";
        return null;
    };

    /**
     * Creates a VoiceMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof VoiceMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {VoiceMessage} VoiceMessage
     */
    VoiceMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.VoiceMessage)
            return object;
        let message = new $root.VoiceMessage();
        if (object.url != null)
            message.url = String(object.url);
        if (object.duration != null)
            message.duration = object.duration | 0;
        if (object.size != null)
            if ($util.Long)
                (message.size = $util.Long.fromValue(object.size)).unsigned = false;
            else if (typeof object.size === "string")
                message.size = parseInt(object.size, 10);
            else if (typeof object.size === "number")
                message.size = object.size;
            else if (typeof object.size === "object")
                message.size = new $util.LongBits(object.size.low >>> 0, object.size.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from a VoiceMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof VoiceMessage
     * @static
     * @param {VoiceMessage} message VoiceMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    VoiceMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.url = "";
            object.duration = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.size = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.size = options.longs === String ? "0" : 0;
        }
        if (message.url != null && message.hasOwnProperty("url"))
            object.url = message.url;
        if (message.duration != null && message.hasOwnProperty("duration"))
            object.duration = message.duration;
        if (message.size != null && message.hasOwnProperty("size"))
            if (typeof message.size === "number")
                object.size = options.longs === String ? String(message.size) : message.size;
            else
                object.size = options.longs === String ? $util.Long.prototype.toString.call(message.size) : options.longs === Number ? new $util.LongBits(message.size.low >>> 0, message.size.high >>> 0).toNumber() : message.size;
        return object;
    };

    /**
     * Converts this VoiceMessage to JSON.
     * @function toJSON
     * @memberof VoiceMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    VoiceMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for VoiceMessage
     * @function getTypeUrl
     * @memberof VoiceMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    VoiceMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/VoiceMessage";
    };

    return VoiceMessage;
})();

export const VideoMessage = $root.VideoMessage = (() => {

    /**
     * Properties of a VideoMessage.
     * @exports IVideoMessage
     * @interface IVideoMessage
     * @property {string|null} [url] VideoMessage url
     * @property {string|null} [coverUrl] VideoMessage coverUrl
     * @property {number|null} [duration] VideoMessage duration
     * @property {number|null} [width] VideoMessage width
     * @property {number|null} [height] VideoMessage height
     * @property {number|Long|null} [size] VideoMessage size
     */

    /**
     * Constructs a new VideoMessage.
     * @exports VideoMessage
     * @classdesc Represents a VideoMessage.
     * @implements IVideoMessage
     * @constructor
     * @param {IVideoMessage=} [properties] Properties to set
     */
    function VideoMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * VideoMessage url.
     * @member {string} url
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.url = "";

    /**
     * VideoMessage coverUrl.
     * @member {string} coverUrl
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.coverUrl = "";

    /**
     * VideoMessage duration.
     * @member {number} duration
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.duration = 0;

    /**
     * VideoMessage width.
     * @member {number} width
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.width = 0;

    /**
     * VideoMessage height.
     * @member {number} height
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.height = 0;

    /**
     * VideoMessage size.
     * @member {number|Long} size
     * @memberof VideoMessage
     * @instance
     */
    VideoMessage.prototype.size = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new VideoMessage instance using the specified properties.
     * @function create
     * @memberof VideoMessage
     * @static
     * @param {IVideoMessage=} [properties] Properties to set
     * @returns {VideoMessage} VideoMessage instance
     */
    VideoMessage.create = function create(properties) {
        return new VideoMessage(properties);
    };

    /**
     * Encodes the specified VideoMessage message. Does not implicitly {@link VideoMessage.verify|verify} messages.
     * @function encode
     * @memberof VideoMessage
     * @static
     * @param {IVideoMessage} message VideoMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    VideoMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.url != null && Object.hasOwnProperty.call(message, "url"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.url);
        if (message.coverUrl != null && Object.hasOwnProperty.call(message, "coverUrl"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.coverUrl);
        if (message.duration != null && Object.hasOwnProperty.call(message, "duration"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.duration);
        if (message.width != null && Object.hasOwnProperty.call(message, "width"))
            writer.uint32(/* id 4, wireType 0 =*/32).int32(message.width);
        if (message.height != null && Object.hasOwnProperty.call(message, "height"))
            writer.uint32(/* id 5, wireType 0 =*/40).int32(message.height);
        if (message.size != null && Object.hasOwnProperty.call(message, "size"))
            writer.uint32(/* id 6, wireType 0 =*/48).int64(message.size);
        return writer;
    };

    /**
     * Encodes the specified VideoMessage message, length delimited. Does not implicitly {@link VideoMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof VideoMessage
     * @static
     * @param {IVideoMessage} message VideoMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    VideoMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a VideoMessage message from the specified reader or buffer.
     * @function decode
     * @memberof VideoMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {VideoMessage} VideoMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    VideoMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.VideoMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.url = reader.string();
                    break;
                }
            case 2: {
                    message.coverUrl = reader.string();
                    break;
                }
            case 3: {
                    message.duration = reader.int32();
                    break;
                }
            case 4: {
                    message.width = reader.int32();
                    break;
                }
            case 5: {
                    message.height = reader.int32();
                    break;
                }
            case 6: {
                    message.size = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a VideoMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof VideoMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {VideoMessage} VideoMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    VideoMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a VideoMessage message.
     * @function verify
     * @memberof VideoMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    VideoMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.url != null && message.hasOwnProperty("url"))
            if (!$util.isString(message.url))
                return "url: string expected";
        if (message.coverUrl != null && message.hasOwnProperty("coverUrl"))
            if (!$util.isString(message.coverUrl))
                return "coverUrl: string expected";
        if (message.duration != null && message.hasOwnProperty("duration"))
            if (!$util.isInteger(message.duration))
                return "duration: integer expected";
        if (message.width != null && message.hasOwnProperty("width"))
            if (!$util.isInteger(message.width))
                return "width: integer expected";
        if (message.height != null && message.hasOwnProperty("height"))
            if (!$util.isInteger(message.height))
                return "height: integer expected";
        if (message.size != null && message.hasOwnProperty("size"))
            if (!$util.isInteger(message.size) && !(message.size && $util.isInteger(message.size.low) && $util.isInteger(message.size.high)))
                return "size: integer|Long expected";
        return null;
    };

    /**
     * Creates a VideoMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof VideoMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {VideoMessage} VideoMessage
     */
    VideoMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.VideoMessage)
            return object;
        let message = new $root.VideoMessage();
        if (object.url != null)
            message.url = String(object.url);
        if (object.coverUrl != null)
            message.coverUrl = String(object.coverUrl);
        if (object.duration != null)
            message.duration = object.duration | 0;
        if (object.width != null)
            message.width = object.width | 0;
        if (object.height != null)
            message.height = object.height | 0;
        if (object.size != null)
            if ($util.Long)
                (message.size = $util.Long.fromValue(object.size)).unsigned = false;
            else if (typeof object.size === "string")
                message.size = parseInt(object.size, 10);
            else if (typeof object.size === "number")
                message.size = object.size;
            else if (typeof object.size === "object")
                message.size = new $util.LongBits(object.size.low >>> 0, object.size.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from a VideoMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof VideoMessage
     * @static
     * @param {VideoMessage} message VideoMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    VideoMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.url = "";
            object.coverUrl = "";
            object.duration = 0;
            object.width = 0;
            object.height = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.size = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.size = options.longs === String ? "0" : 0;
        }
        if (message.url != null && message.hasOwnProperty("url"))
            object.url = message.url;
        if (message.coverUrl != null && message.hasOwnProperty("coverUrl"))
            object.coverUrl = message.coverUrl;
        if (message.duration != null && message.hasOwnProperty("duration"))
            object.duration = message.duration;
        if (message.width != null && message.hasOwnProperty("width"))
            object.width = message.width;
        if (message.height != null && message.hasOwnProperty("height"))
            object.height = message.height;
        if (message.size != null && message.hasOwnProperty("size"))
            if (typeof message.size === "number")
                object.size = options.longs === String ? String(message.size) : message.size;
            else
                object.size = options.longs === String ? $util.Long.prototype.toString.call(message.size) : options.longs === Number ? new $util.LongBits(message.size.low >>> 0, message.size.high >>> 0).toNumber() : message.size;
        return object;
    };

    /**
     * Converts this VideoMessage to JSON.
     * @function toJSON
     * @memberof VideoMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    VideoMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for VideoMessage
     * @function getTypeUrl
     * @memberof VideoMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    VideoMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/VideoMessage";
    };

    return VideoMessage;
})();

export const FileMessage = $root.FileMessage = (() => {

    /**
     * Properties of a FileMessage.
     * @exports IFileMessage
     * @interface IFileMessage
     * @property {string|null} [url] FileMessage url
     * @property {string|null} [fileName] FileMessage fileName
     * @property {number|Long|null} [size] FileMessage size
     * @property {string|null} [fileType] FileMessage fileType
     */

    /**
     * Constructs a new FileMessage.
     * @exports FileMessage
     * @classdesc Represents a FileMessage.
     * @implements IFileMessage
     * @constructor
     * @param {IFileMessage=} [properties] Properties to set
     */
    function FileMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * FileMessage url.
     * @member {string} url
     * @memberof FileMessage
     * @instance
     */
    FileMessage.prototype.url = "";

    /**
     * FileMessage fileName.
     * @member {string} fileName
     * @memberof FileMessage
     * @instance
     */
    FileMessage.prototype.fileName = "";

    /**
     * FileMessage size.
     * @member {number|Long} size
     * @memberof FileMessage
     * @instance
     */
    FileMessage.prototype.size = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * FileMessage fileType.
     * @member {string} fileType
     * @memberof FileMessage
     * @instance
     */
    FileMessage.prototype.fileType = "";

    /**
     * Creates a new FileMessage instance using the specified properties.
     * @function create
     * @memberof FileMessage
     * @static
     * @param {IFileMessage=} [properties] Properties to set
     * @returns {FileMessage} FileMessage instance
     */
    FileMessage.create = function create(properties) {
        return new FileMessage(properties);
    };

    /**
     * Encodes the specified FileMessage message. Does not implicitly {@link FileMessage.verify|verify} messages.
     * @function encode
     * @memberof FileMessage
     * @static
     * @param {IFileMessage} message FileMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    FileMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.url != null && Object.hasOwnProperty.call(message, "url"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.url);
        if (message.fileName != null && Object.hasOwnProperty.call(message, "fileName"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.fileName);
        if (message.size != null && Object.hasOwnProperty.call(message, "size"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.size);
        if (message.fileType != null && Object.hasOwnProperty.call(message, "fileType"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.fileType);
        return writer;
    };

    /**
     * Encodes the specified FileMessage message, length delimited. Does not implicitly {@link FileMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof FileMessage
     * @static
     * @param {IFileMessage} message FileMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    FileMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a FileMessage message from the specified reader or buffer.
     * @function decode
     * @memberof FileMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {FileMessage} FileMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    FileMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.FileMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.url = reader.string();
                    break;
                }
            case 2: {
                    message.fileName = reader.string();
                    break;
                }
            case 3: {
                    message.size = reader.int64();
                    break;
                }
            case 4: {
                    message.fileType = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a FileMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof FileMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {FileMessage} FileMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    FileMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a FileMessage message.
     * @function verify
     * @memberof FileMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    FileMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.url != null && message.hasOwnProperty("url"))
            if (!$util.isString(message.url))
                return "url: string expected";
        if (message.fileName != null && message.hasOwnProperty("fileName"))
            if (!$util.isString(message.fileName))
                return "fileName: string expected";
        if (message.size != null && message.hasOwnProperty("size"))
            if (!$util.isInteger(message.size) && !(message.size && $util.isInteger(message.size.low) && $util.isInteger(message.size.high)))
                return "size: integer|Long expected";
        if (message.fileType != null && message.hasOwnProperty("fileType"))
            if (!$util.isString(message.fileType))
                return "fileType: string expected";
        return null;
    };

    /**
     * Creates a FileMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof FileMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {FileMessage} FileMessage
     */
    FileMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.FileMessage)
            return object;
        let message = new $root.FileMessage();
        if (object.url != null)
            message.url = String(object.url);
        if (object.fileName != null)
            message.fileName = String(object.fileName);
        if (object.size != null)
            if ($util.Long)
                (message.size = $util.Long.fromValue(object.size)).unsigned = false;
            else if (typeof object.size === "string")
                message.size = parseInt(object.size, 10);
            else if (typeof object.size === "number")
                message.size = object.size;
            else if (typeof object.size === "object")
                message.size = new $util.LongBits(object.size.low >>> 0, object.size.high >>> 0).toNumber();
        if (object.fileType != null)
            message.fileType = String(object.fileType);
        return message;
    };

    /**
     * Creates a plain object from a FileMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof FileMessage
     * @static
     * @param {FileMessage} message FileMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    FileMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.url = "";
            object.fileName = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.size = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.size = options.longs === String ? "0" : 0;
            object.fileType = "";
        }
        if (message.url != null && message.hasOwnProperty("url"))
            object.url = message.url;
        if (message.fileName != null && message.hasOwnProperty("fileName"))
            object.fileName = message.fileName;
        if (message.size != null && message.hasOwnProperty("size"))
            if (typeof message.size === "number")
                object.size = options.longs === String ? String(message.size) : message.size;
            else
                object.size = options.longs === String ? $util.Long.prototype.toString.call(message.size) : options.longs === Number ? new $util.LongBits(message.size.low >>> 0, message.size.high >>> 0).toNumber() : message.size;
        if (message.fileType != null && message.hasOwnProperty("fileType"))
            object.fileType = message.fileType;
        return object;
    };

    /**
     * Converts this FileMessage to JSON.
     * @function toJSON
     * @memberof FileMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    FileMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for FileMessage
     * @function getTypeUrl
     * @memberof FileMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    FileMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/FileMessage";
    };

    return FileMessage;
})();

export const LocationMessage = $root.LocationMessage = (() => {

    /**
     * Properties of a LocationMessage.
     * @exports ILocationMessage
     * @interface ILocationMessage
     * @property {number|null} [latitude] LocationMessage latitude
     * @property {number|null} [longitude] LocationMessage longitude
     * @property {string|null} [address] LocationMessage address
     */

    /**
     * Constructs a new LocationMessage.
     * @exports LocationMessage
     * @classdesc Represents a LocationMessage.
     * @implements ILocationMessage
     * @constructor
     * @param {ILocationMessage=} [properties] Properties to set
     */
    function LocationMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * LocationMessage latitude.
     * @member {number} latitude
     * @memberof LocationMessage
     * @instance
     */
    LocationMessage.prototype.latitude = 0;

    /**
     * LocationMessage longitude.
     * @member {number} longitude
     * @memberof LocationMessage
     * @instance
     */
    LocationMessage.prototype.longitude = 0;

    /**
     * LocationMessage address.
     * @member {string} address
     * @memberof LocationMessage
     * @instance
     */
    LocationMessage.prototype.address = "";

    /**
     * Creates a new LocationMessage instance using the specified properties.
     * @function create
     * @memberof LocationMessage
     * @static
     * @param {ILocationMessage=} [properties] Properties to set
     * @returns {LocationMessage} LocationMessage instance
     */
    LocationMessage.create = function create(properties) {
        return new LocationMessage(properties);
    };

    /**
     * Encodes the specified LocationMessage message. Does not implicitly {@link LocationMessage.verify|verify} messages.
     * @function encode
     * @memberof LocationMessage
     * @static
     * @param {ILocationMessage} message LocationMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    LocationMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.latitude != null && Object.hasOwnProperty.call(message, "latitude"))
            writer.uint32(/* id 1, wireType 1 =*/9).double(message.latitude);
        if (message.longitude != null && Object.hasOwnProperty.call(message, "longitude"))
            writer.uint32(/* id 2, wireType 1 =*/17).double(message.longitude);
        if (message.address != null && Object.hasOwnProperty.call(message, "address"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.address);
        return writer;
    };

    /**
     * Encodes the specified LocationMessage message, length delimited. Does not implicitly {@link LocationMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof LocationMessage
     * @static
     * @param {ILocationMessage} message LocationMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    LocationMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a LocationMessage message from the specified reader or buffer.
     * @function decode
     * @memberof LocationMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {LocationMessage} LocationMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    LocationMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.LocationMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.latitude = reader.double();
                    break;
                }
            case 2: {
                    message.longitude = reader.double();
                    break;
                }
            case 3: {
                    message.address = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a LocationMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof LocationMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {LocationMessage} LocationMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    LocationMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a LocationMessage message.
     * @function verify
     * @memberof LocationMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    LocationMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.latitude != null && message.hasOwnProperty("latitude"))
            if (typeof message.latitude !== "number")
                return "latitude: number expected";
        if (message.longitude != null && message.hasOwnProperty("longitude"))
            if (typeof message.longitude !== "number")
                return "longitude: number expected";
        if (message.address != null && message.hasOwnProperty("address"))
            if (!$util.isString(message.address))
                return "address: string expected";
        return null;
    };

    /**
     * Creates a LocationMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof LocationMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {LocationMessage} LocationMessage
     */
    LocationMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.LocationMessage)
            return object;
        let message = new $root.LocationMessage();
        if (object.latitude != null)
            message.latitude = Number(object.latitude);
        if (object.longitude != null)
            message.longitude = Number(object.longitude);
        if (object.address != null)
            message.address = String(object.address);
        return message;
    };

    /**
     * Creates a plain object from a LocationMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof LocationMessage
     * @static
     * @param {LocationMessage} message LocationMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    LocationMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.latitude = 0;
            object.longitude = 0;
            object.address = "";
        }
        if (message.latitude != null && message.hasOwnProperty("latitude"))
            object.latitude = options.json && !isFinite(message.latitude) ? String(message.latitude) : message.latitude;
        if (message.longitude != null && message.hasOwnProperty("longitude"))
            object.longitude = options.json && !isFinite(message.longitude) ? String(message.longitude) : message.longitude;
        if (message.address != null && message.hasOwnProperty("address"))
            object.address = message.address;
        return object;
    };

    /**
     * Converts this LocationMessage to JSON.
     * @function toJSON
     * @memberof LocationMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    LocationMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for LocationMessage
     * @function getTypeUrl
     * @memberof LocationMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    LocationMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/LocationMessage";
    };

    return LocationMessage;
})();

export const ReadReceiptMessage = $root.ReadReceiptMessage = (() => {

    /**
     * Properties of a ReadReceiptMessage.
     * @exports IReadReceiptMessage
     * @interface IReadReceiptMessage
     * @property {Array.<number|Long>|null} [messageIds] ReadReceiptMessage messageIds
     */

    /**
     * Constructs a new ReadReceiptMessage.
     * @exports ReadReceiptMessage
     * @classdesc Represents a ReadReceiptMessage.
     * @implements IReadReceiptMessage
     * @constructor
     * @param {IReadReceiptMessage=} [properties] Properties to set
     */
    function ReadReceiptMessage(properties) {
        this.messageIds = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * ReadReceiptMessage messageIds.
     * @member {Array.<number|Long>} messageIds
     * @memberof ReadReceiptMessage
     * @instance
     */
    ReadReceiptMessage.prototype.messageIds = $util.emptyArray;

    /**
     * Creates a new ReadReceiptMessage instance using the specified properties.
     * @function create
     * @memberof ReadReceiptMessage
     * @static
     * @param {IReadReceiptMessage=} [properties] Properties to set
     * @returns {ReadReceiptMessage} ReadReceiptMessage instance
     */
    ReadReceiptMessage.create = function create(properties) {
        return new ReadReceiptMessage(properties);
    };

    /**
     * Encodes the specified ReadReceiptMessage message. Does not implicitly {@link ReadReceiptMessage.verify|verify} messages.
     * @function encode
     * @memberof ReadReceiptMessage
     * @static
     * @param {IReadReceiptMessage} message ReadReceiptMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ReadReceiptMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.messageIds != null && message.messageIds.length) {
            writer.uint32(/* id 1, wireType 2 =*/10).fork();
            for (let i = 0; i < message.messageIds.length; ++i)
                writer.int64(message.messageIds[i]);
            writer.ldelim();
        }
        return writer;
    };

    /**
     * Encodes the specified ReadReceiptMessage message, length delimited. Does not implicitly {@link ReadReceiptMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof ReadReceiptMessage
     * @static
     * @param {IReadReceiptMessage} message ReadReceiptMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ReadReceiptMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a ReadReceiptMessage message from the specified reader or buffer.
     * @function decode
     * @memberof ReadReceiptMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {ReadReceiptMessage} ReadReceiptMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ReadReceiptMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.ReadReceiptMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    if (!(message.messageIds && message.messageIds.length))
                        message.messageIds = [];
                    if ((tag & 7) === 2) {
                        let end2 = reader.uint32() + reader.pos;
                        while (reader.pos < end2)
                            message.messageIds.push(reader.int64());
                    } else
                        message.messageIds.push(reader.int64());
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a ReadReceiptMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof ReadReceiptMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {ReadReceiptMessage} ReadReceiptMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ReadReceiptMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a ReadReceiptMessage message.
     * @function verify
     * @memberof ReadReceiptMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    ReadReceiptMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.messageIds != null && message.hasOwnProperty("messageIds")) {
            if (!Array.isArray(message.messageIds))
                return "messageIds: array expected";
            for (let i = 0; i < message.messageIds.length; ++i)
                if (!$util.isInteger(message.messageIds[i]) && !(message.messageIds[i] && $util.isInteger(message.messageIds[i].low) && $util.isInteger(message.messageIds[i].high)))
                    return "messageIds: integer|Long[] expected";
        }
        return null;
    };

    /**
     * Creates a ReadReceiptMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof ReadReceiptMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {ReadReceiptMessage} ReadReceiptMessage
     */
    ReadReceiptMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.ReadReceiptMessage)
            return object;
        let message = new $root.ReadReceiptMessage();
        if (object.messageIds) {
            if (!Array.isArray(object.messageIds))
                throw TypeError(".ReadReceiptMessage.messageIds: array expected");
            message.messageIds = [];
            for (let i = 0; i < object.messageIds.length; ++i)
                if ($util.Long)
                    (message.messageIds[i] = $util.Long.fromValue(object.messageIds[i])).unsigned = false;
                else if (typeof object.messageIds[i] === "string")
                    message.messageIds[i] = parseInt(object.messageIds[i], 10);
                else if (typeof object.messageIds[i] === "number")
                    message.messageIds[i] = object.messageIds[i];
                else if (typeof object.messageIds[i] === "object")
                    message.messageIds[i] = new $util.LongBits(object.messageIds[i].low >>> 0, object.messageIds[i].high >>> 0).toNumber();
        }
        return message;
    };

    /**
     * Creates a plain object from a ReadReceiptMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof ReadReceiptMessage
     * @static
     * @param {ReadReceiptMessage} message ReadReceiptMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    ReadReceiptMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults)
            object.messageIds = [];
        if (message.messageIds && message.messageIds.length) {
            object.messageIds = [];
            for (let j = 0; j < message.messageIds.length; ++j)
                if (typeof message.messageIds[j] === "number")
                    object.messageIds[j] = options.longs === String ? String(message.messageIds[j]) : message.messageIds[j];
                else
                    object.messageIds[j] = options.longs === String ? $util.Long.prototype.toString.call(message.messageIds[j]) : options.longs === Number ? new $util.LongBits(message.messageIds[j].low >>> 0, message.messageIds[j].high >>> 0).toNumber() : message.messageIds[j];
        }
        return object;
    };

    /**
     * Converts this ReadReceiptMessage to JSON.
     * @function toJSON
     * @memberof ReadReceiptMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    ReadReceiptMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for ReadReceiptMessage
     * @function getTypeUrl
     * @memberof ReadReceiptMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    ReadReceiptMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/ReadReceiptMessage";
    };

    return ReadReceiptMessage;
})();

export const RecallMessage = $root.RecallMessage = (() => {

    /**
     * Properties of a RecallMessage.
     * @exports IRecallMessage
     * @interface IRecallMessage
     * @property {number|Long|null} [messageId] RecallMessage messageId
     */

    /**
     * Constructs a new RecallMessage.
     * @exports RecallMessage
     * @classdesc Represents a RecallMessage.
     * @implements IRecallMessage
     * @constructor
     * @param {IRecallMessage=} [properties] Properties to set
     */
    function RecallMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * RecallMessage messageId.
     * @member {number|Long} messageId
     * @memberof RecallMessage
     * @instance
     */
    RecallMessage.prototype.messageId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * Creates a new RecallMessage instance using the specified properties.
     * @function create
     * @memberof RecallMessage
     * @static
     * @param {IRecallMessage=} [properties] Properties to set
     * @returns {RecallMessage} RecallMessage instance
     */
    RecallMessage.create = function create(properties) {
        return new RecallMessage(properties);
    };

    /**
     * Encodes the specified RecallMessage message. Does not implicitly {@link RecallMessage.verify|verify} messages.
     * @function encode
     * @memberof RecallMessage
     * @static
     * @param {IRecallMessage} message RecallMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    RecallMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.messageId != null && Object.hasOwnProperty.call(message, "messageId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.messageId);
        return writer;
    };

    /**
     * Encodes the specified RecallMessage message, length delimited. Does not implicitly {@link RecallMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof RecallMessage
     * @static
     * @param {IRecallMessage} message RecallMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    RecallMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a RecallMessage message from the specified reader or buffer.
     * @function decode
     * @memberof RecallMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {RecallMessage} RecallMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    RecallMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.RecallMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.messageId = reader.int64();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a RecallMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof RecallMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {RecallMessage} RecallMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    RecallMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a RecallMessage message.
     * @function verify
     * @memberof RecallMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    RecallMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (!$util.isInteger(message.messageId) && !(message.messageId && $util.isInteger(message.messageId.low) && $util.isInteger(message.messageId.high)))
                return "messageId: integer|Long expected";
        return null;
    };

    /**
     * Creates a RecallMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof RecallMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {RecallMessage} RecallMessage
     */
    RecallMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.RecallMessage)
            return object;
        let message = new $root.RecallMessage();
        if (object.messageId != null)
            if ($util.Long)
                (message.messageId = $util.Long.fromValue(object.messageId)).unsigned = false;
            else if (typeof object.messageId === "string")
                message.messageId = parseInt(object.messageId, 10);
            else if (typeof object.messageId === "number")
                message.messageId = object.messageId;
            else if (typeof object.messageId === "object")
                message.messageId = new $util.LongBits(object.messageId.low >>> 0, object.messageId.high >>> 0).toNumber();
        return message;
    };

    /**
     * Creates a plain object from a RecallMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof RecallMessage
     * @static
     * @param {RecallMessage} message RecallMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    RecallMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults)
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.messageId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.messageId = options.longs === String ? "0" : 0;
        if (message.messageId != null && message.hasOwnProperty("messageId"))
            if (typeof message.messageId === "number")
                object.messageId = options.longs === String ? String(message.messageId) : message.messageId;
            else
                object.messageId = options.longs === String ? $util.Long.prototype.toString.call(message.messageId) : options.longs === Number ? new $util.LongBits(message.messageId.low >>> 0, message.messageId.high >>> 0).toNumber() : message.messageId;
        return object;
    };

    /**
     * Converts this RecallMessage to JSON.
     * @function toJSON
     * @memberof RecallMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    RecallMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for RecallMessage
     * @function getTypeUrl
     * @memberof RecallMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    RecallMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/RecallMessage";
    };

    return RecallMessage;
})();

export const QuoteReplyMessage = $root.QuoteReplyMessage = (() => {

    /**
     * Properties of a QuoteReplyMessage.
     * @exports IQuoteReplyMessage
     * @interface IQuoteReplyMessage
     * @property {number|Long|null} [quoteMessageId] QuoteReplyMessage quoteMessageId
     * @property {string|null} [quoteContent] QuoteReplyMessage quoteContent
     * @property {number|Long|null} [quoteSenderId] QuoteReplyMessage quoteSenderId
     * @property {string|null} [quoteSenderName] QuoteReplyMessage quoteSenderName
     * @property {string|null} [replyContent] QuoteReplyMessage replyContent
     * @property {Array.<number|Long>|null} [atUserIds] QuoteReplyMessage atUserIds
     * @property {Array.<IMentionUser>|null} [mentions] QuoteReplyMessage mentions
     */

    /**
     * Constructs a new QuoteReplyMessage.
     * @exports QuoteReplyMessage
     * @classdesc Represents a QuoteReplyMessage.
     * @implements IQuoteReplyMessage
     * @constructor
     * @param {IQuoteReplyMessage=} [properties] Properties to set
     */
    function QuoteReplyMessage(properties) {
        this.atUserIds = [];
        this.mentions = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * QuoteReplyMessage quoteMessageId.
     * @member {number|Long} quoteMessageId
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.quoteMessageId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * QuoteReplyMessage quoteContent.
     * @member {string} quoteContent
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.quoteContent = "";

    /**
     * QuoteReplyMessage quoteSenderId.
     * @member {number|Long} quoteSenderId
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.quoteSenderId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * QuoteReplyMessage quoteSenderName.
     * @member {string} quoteSenderName
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.quoteSenderName = "";

    /**
     * QuoteReplyMessage replyContent.
     * @member {string} replyContent
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.replyContent = "";

    /**
     * QuoteReplyMessage atUserIds.
     * @member {Array.<number|Long>} atUserIds
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.atUserIds = $util.emptyArray;

    /**
     * QuoteReplyMessage mentions.
     * @member {Array.<IMentionUser>} mentions
     * @memberof QuoteReplyMessage
     * @instance
     */
    QuoteReplyMessage.prototype.mentions = $util.emptyArray;

    /**
     * Creates a new QuoteReplyMessage instance using the specified properties.
     * @function create
     * @memberof QuoteReplyMessage
     * @static
     * @param {IQuoteReplyMessage=} [properties] Properties to set
     * @returns {QuoteReplyMessage} QuoteReplyMessage instance
     */
    QuoteReplyMessage.create = function create(properties) {
        return new QuoteReplyMessage(properties);
    };

    /**
     * Encodes the specified QuoteReplyMessage message. Does not implicitly {@link QuoteReplyMessage.verify|verify} messages.
     * @function encode
     * @memberof QuoteReplyMessage
     * @static
     * @param {IQuoteReplyMessage} message QuoteReplyMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    QuoteReplyMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.quoteMessageId != null && Object.hasOwnProperty.call(message, "quoteMessageId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.quoteMessageId);
        if (message.quoteContent != null && Object.hasOwnProperty.call(message, "quoteContent"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.quoteContent);
        if (message.quoteSenderId != null && Object.hasOwnProperty.call(message, "quoteSenderId"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.quoteSenderId);
        if (message.quoteSenderName != null && Object.hasOwnProperty.call(message, "quoteSenderName"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.quoteSenderName);
        if (message.replyContent != null && Object.hasOwnProperty.call(message, "replyContent"))
            writer.uint32(/* id 5, wireType 2 =*/42).string(message.replyContent);
        if (message.atUserIds != null && message.atUserIds.length) {
            writer.uint32(/* id 6, wireType 2 =*/50).fork();
            for (let i = 0; i < message.atUserIds.length; ++i)
                writer.int64(message.atUserIds[i]);
            writer.ldelim();
        }
        if (message.mentions != null && message.mentions.length)
            for (let i = 0; i < message.mentions.length; ++i)
                $root.MentionUser.encode(message.mentions[i], writer.uint32(/* id 7, wireType 2 =*/58).fork()).ldelim();
        return writer;
    };

    /**
     * Encodes the specified QuoteReplyMessage message, length delimited. Does not implicitly {@link QuoteReplyMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof QuoteReplyMessage
     * @static
     * @param {IQuoteReplyMessage} message QuoteReplyMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    QuoteReplyMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a QuoteReplyMessage message from the specified reader or buffer.
     * @function decode
     * @memberof QuoteReplyMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {QuoteReplyMessage} QuoteReplyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    QuoteReplyMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.QuoteReplyMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.quoteMessageId = reader.int64();
                    break;
                }
            case 2: {
                    message.quoteContent = reader.string();
                    break;
                }
            case 3: {
                    message.quoteSenderId = reader.int64();
                    break;
                }
            case 4: {
                    message.quoteSenderName = reader.string();
                    break;
                }
            case 5: {
                    message.replyContent = reader.string();
                    break;
                }
            case 6: {
                    if (!(message.atUserIds && message.atUserIds.length))
                        message.atUserIds = [];
                    if ((tag & 7) === 2) {
                        let end2 = reader.uint32() + reader.pos;
                        while (reader.pos < end2)
                            message.atUserIds.push(reader.int64());
                    } else
                        message.atUserIds.push(reader.int64());
                    break;
                }
            case 7: {
                    if (!(message.mentions && message.mentions.length))
                        message.mentions = [];
                    message.mentions.push($root.MentionUser.decode(reader, reader.uint32()));
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a QuoteReplyMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof QuoteReplyMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {QuoteReplyMessage} QuoteReplyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    QuoteReplyMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a QuoteReplyMessage message.
     * @function verify
     * @memberof QuoteReplyMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    QuoteReplyMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.quoteMessageId != null && message.hasOwnProperty("quoteMessageId"))
            if (!$util.isInteger(message.quoteMessageId) && !(message.quoteMessageId && $util.isInteger(message.quoteMessageId.low) && $util.isInteger(message.quoteMessageId.high)))
                return "quoteMessageId: integer|Long expected";
        if (message.quoteContent != null && message.hasOwnProperty("quoteContent"))
            if (!$util.isString(message.quoteContent))
                return "quoteContent: string expected";
        if (message.quoteSenderId != null && message.hasOwnProperty("quoteSenderId"))
            if (!$util.isInteger(message.quoteSenderId) && !(message.quoteSenderId && $util.isInteger(message.quoteSenderId.low) && $util.isInteger(message.quoteSenderId.high)))
                return "quoteSenderId: integer|Long expected";
        if (message.quoteSenderName != null && message.hasOwnProperty("quoteSenderName"))
            if (!$util.isString(message.quoteSenderName))
                return "quoteSenderName: string expected";
        if (message.replyContent != null && message.hasOwnProperty("replyContent"))
            if (!$util.isString(message.replyContent))
                return "replyContent: string expected";
        if (message.atUserIds != null && message.hasOwnProperty("atUserIds")) {
            if (!Array.isArray(message.atUserIds))
                return "atUserIds: array expected";
            for (let i = 0; i < message.atUserIds.length; ++i)
                if (!$util.isInteger(message.atUserIds[i]) && !(message.atUserIds[i] && $util.isInteger(message.atUserIds[i].low) && $util.isInteger(message.atUserIds[i].high)))
                    return "atUserIds: integer|Long[] expected";
        }
        if (message.mentions != null && message.hasOwnProperty("mentions")) {
            if (!Array.isArray(message.mentions))
                return "mentions: array expected";
            for (let i = 0; i < message.mentions.length; ++i) {
                let error = $root.MentionUser.verify(message.mentions[i]);
                if (error)
                    return "mentions." + error;
            }
        }
        return null;
    };

    /**
     * Creates a QuoteReplyMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof QuoteReplyMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {QuoteReplyMessage} QuoteReplyMessage
     */
    QuoteReplyMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.QuoteReplyMessage)
            return object;
        let message = new $root.QuoteReplyMessage();
        if (object.quoteMessageId != null)
            if ($util.Long)
                (message.quoteMessageId = $util.Long.fromValue(object.quoteMessageId)).unsigned = false;
            else if (typeof object.quoteMessageId === "string")
                message.quoteMessageId = parseInt(object.quoteMessageId, 10);
            else if (typeof object.quoteMessageId === "number")
                message.quoteMessageId = object.quoteMessageId;
            else if (typeof object.quoteMessageId === "object")
                message.quoteMessageId = new $util.LongBits(object.quoteMessageId.low >>> 0, object.quoteMessageId.high >>> 0).toNumber();
        if (object.quoteContent != null)
            message.quoteContent = String(object.quoteContent);
        if (object.quoteSenderId != null)
            if ($util.Long)
                (message.quoteSenderId = $util.Long.fromValue(object.quoteSenderId)).unsigned = false;
            else if (typeof object.quoteSenderId === "string")
                message.quoteSenderId = parseInt(object.quoteSenderId, 10);
            else if (typeof object.quoteSenderId === "number")
                message.quoteSenderId = object.quoteSenderId;
            else if (typeof object.quoteSenderId === "object")
                message.quoteSenderId = new $util.LongBits(object.quoteSenderId.low >>> 0, object.quoteSenderId.high >>> 0).toNumber();
        if (object.quoteSenderName != null)
            message.quoteSenderName = String(object.quoteSenderName);
        if (object.replyContent != null)
            message.replyContent = String(object.replyContent);
        if (object.atUserIds) {
            if (!Array.isArray(object.atUserIds))
                throw TypeError(".QuoteReplyMessage.atUserIds: array expected");
            message.atUserIds = [];
            for (let i = 0; i < object.atUserIds.length; ++i)
                if ($util.Long)
                    (message.atUserIds[i] = $util.Long.fromValue(object.atUserIds[i])).unsigned = false;
                else if (typeof object.atUserIds[i] === "string")
                    message.atUserIds[i] = parseInt(object.atUserIds[i], 10);
                else if (typeof object.atUserIds[i] === "number")
                    message.atUserIds[i] = object.atUserIds[i];
                else if (typeof object.atUserIds[i] === "object")
                    message.atUserIds[i] = new $util.LongBits(object.atUserIds[i].low >>> 0, object.atUserIds[i].high >>> 0).toNumber();
        }
        if (object.mentions) {
            if (!Array.isArray(object.mentions))
                throw TypeError(".QuoteReplyMessage.mentions: array expected");
            message.mentions = [];
            for (let i = 0; i < object.mentions.length; ++i) {
                if (typeof object.mentions[i] !== "object")
                    throw TypeError(".QuoteReplyMessage.mentions: object expected");
                message.mentions[i] = $root.MentionUser.fromObject(object.mentions[i]);
            }
        }
        return message;
    };

    /**
     * Creates a plain object from a QuoteReplyMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof QuoteReplyMessage
     * @static
     * @param {QuoteReplyMessage} message QuoteReplyMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    QuoteReplyMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults) {
            object.atUserIds = [];
            object.mentions = [];
        }
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.quoteMessageId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.quoteMessageId = options.longs === String ? "0" : 0;
            object.quoteContent = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.quoteSenderId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.quoteSenderId = options.longs === String ? "0" : 0;
            object.quoteSenderName = "";
            object.replyContent = "";
        }
        if (message.quoteMessageId != null && message.hasOwnProperty("quoteMessageId"))
            if (typeof message.quoteMessageId === "number")
                object.quoteMessageId = options.longs === String ? String(message.quoteMessageId) : message.quoteMessageId;
            else
                object.quoteMessageId = options.longs === String ? $util.Long.prototype.toString.call(message.quoteMessageId) : options.longs === Number ? new $util.LongBits(message.quoteMessageId.low >>> 0, message.quoteMessageId.high >>> 0).toNumber() : message.quoteMessageId;
        if (message.quoteContent != null && message.hasOwnProperty("quoteContent"))
            object.quoteContent = message.quoteContent;
        if (message.quoteSenderId != null && message.hasOwnProperty("quoteSenderId"))
            if (typeof message.quoteSenderId === "number")
                object.quoteSenderId = options.longs === String ? String(message.quoteSenderId) : message.quoteSenderId;
            else
                object.quoteSenderId = options.longs === String ? $util.Long.prototype.toString.call(message.quoteSenderId) : options.longs === Number ? new $util.LongBits(message.quoteSenderId.low >>> 0, message.quoteSenderId.high >>> 0).toNumber() : message.quoteSenderId;
        if (message.quoteSenderName != null && message.hasOwnProperty("quoteSenderName"))
            object.quoteSenderName = message.quoteSenderName;
        if (message.replyContent != null && message.hasOwnProperty("replyContent"))
            object.replyContent = message.replyContent;
        if (message.atUserIds && message.atUserIds.length) {
            object.atUserIds = [];
            for (let j = 0; j < message.atUserIds.length; ++j)
                if (typeof message.atUserIds[j] === "number")
                    object.atUserIds[j] = options.longs === String ? String(message.atUserIds[j]) : message.atUserIds[j];
                else
                    object.atUserIds[j] = options.longs === String ? $util.Long.prototype.toString.call(message.atUserIds[j]) : options.longs === Number ? new $util.LongBits(message.atUserIds[j].low >>> 0, message.atUserIds[j].high >>> 0).toNumber() : message.atUserIds[j];
        }
        if (message.mentions && message.mentions.length) {
            object.mentions = [];
            for (let j = 0; j < message.mentions.length; ++j)
                object.mentions[j] = $root.MentionUser.toObject(message.mentions[j], options);
        }
        return object;
    };

    /**
     * Converts this QuoteReplyMessage to JSON.
     * @function toJSON
     * @memberof QuoteReplyMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    QuoteReplyMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for QuoteReplyMessage
     * @function getTypeUrl
     * @memberof QuoteReplyMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    QuoteReplyMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/QuoteReplyMessage";
    };

    return QuoteReplyMessage;
})();

export const TypingMessage = $root.TypingMessage = (() => {

    /**
     * Properties of a TypingMessage.
     * @exports ITypingMessage
     * @interface ITypingMessage
     * @property {number|Long|null} [targetUserId] TypingMessage targetUserId
     * @property {number|Long|null} [groupId] TypingMessage groupId
     * @property {boolean|null} [isTyping] TypingMessage isTyping
     */

    /**
     * Constructs a new TypingMessage.
     * @exports TypingMessage
     * @classdesc Represents a TypingMessage.
     * @implements ITypingMessage
     * @constructor
     * @param {ITypingMessage=} [properties] Properties to set
     */
    function TypingMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * TypingMessage targetUserId.
     * @member {number|Long} targetUserId
     * @memberof TypingMessage
     * @instance
     */
    TypingMessage.prototype.targetUserId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * TypingMessage groupId.
     * @member {number|Long} groupId
     * @memberof TypingMessage
     * @instance
     */
    TypingMessage.prototype.groupId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * TypingMessage isTyping.
     * @member {boolean} isTyping
     * @memberof TypingMessage
     * @instance
     */
    TypingMessage.prototype.isTyping = false;

    /**
     * Creates a new TypingMessage instance using the specified properties.
     * @function create
     * @memberof TypingMessage
     * @static
     * @param {ITypingMessage=} [properties] Properties to set
     * @returns {TypingMessage} TypingMessage instance
     */
    TypingMessage.create = function create(properties) {
        return new TypingMessage(properties);
    };

    /**
     * Encodes the specified TypingMessage message. Does not implicitly {@link TypingMessage.verify|verify} messages.
     * @function encode
     * @memberof TypingMessage
     * @static
     * @param {ITypingMessage} message TypingMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TypingMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.targetUserId != null && Object.hasOwnProperty.call(message, "targetUserId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.targetUserId);
        if (message.groupId != null && Object.hasOwnProperty.call(message, "groupId"))
            writer.uint32(/* id 2, wireType 0 =*/16).int64(message.groupId);
        if (message.isTyping != null && Object.hasOwnProperty.call(message, "isTyping"))
            writer.uint32(/* id 3, wireType 0 =*/24).bool(message.isTyping);
        return writer;
    };

    /**
     * Encodes the specified TypingMessage message, length delimited. Does not implicitly {@link TypingMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof TypingMessage
     * @static
     * @param {ITypingMessage} message TypingMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TypingMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a TypingMessage message from the specified reader or buffer.
     * @function decode
     * @memberof TypingMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {TypingMessage} TypingMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TypingMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.TypingMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.targetUserId = reader.int64();
                    break;
                }
            case 2: {
                    message.groupId = reader.int64();
                    break;
                }
            case 3: {
                    message.isTyping = reader.bool();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a TypingMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof TypingMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {TypingMessage} TypingMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TypingMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a TypingMessage message.
     * @function verify
     * @memberof TypingMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    TypingMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.targetUserId != null && message.hasOwnProperty("targetUserId"))
            if (!$util.isInteger(message.targetUserId) && !(message.targetUserId && $util.isInteger(message.targetUserId.low) && $util.isInteger(message.targetUserId.high)))
                return "targetUserId: integer|Long expected";
        if (message.groupId != null && message.hasOwnProperty("groupId"))
            if (!$util.isInteger(message.groupId) && !(message.groupId && $util.isInteger(message.groupId.low) && $util.isInteger(message.groupId.high)))
                return "groupId: integer|Long expected";
        if (message.isTyping != null && message.hasOwnProperty("isTyping"))
            if (typeof message.isTyping !== "boolean")
                return "isTyping: boolean expected";
        return null;
    };

    /**
     * Creates a TypingMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof TypingMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {TypingMessage} TypingMessage
     */
    TypingMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.TypingMessage)
            return object;
        let message = new $root.TypingMessage();
        if (object.targetUserId != null)
            if ($util.Long)
                (message.targetUserId = $util.Long.fromValue(object.targetUserId)).unsigned = false;
            else if (typeof object.targetUserId === "string")
                message.targetUserId = parseInt(object.targetUserId, 10);
            else if (typeof object.targetUserId === "number")
                message.targetUserId = object.targetUserId;
            else if (typeof object.targetUserId === "object")
                message.targetUserId = new $util.LongBits(object.targetUserId.low >>> 0, object.targetUserId.high >>> 0).toNumber();
        if (object.groupId != null)
            if ($util.Long)
                (message.groupId = $util.Long.fromValue(object.groupId)).unsigned = false;
            else if (typeof object.groupId === "string")
                message.groupId = parseInt(object.groupId, 10);
            else if (typeof object.groupId === "number")
                message.groupId = object.groupId;
            else if (typeof object.groupId === "object")
                message.groupId = new $util.LongBits(object.groupId.low >>> 0, object.groupId.high >>> 0).toNumber();
        if (object.isTyping != null)
            message.isTyping = Boolean(object.isTyping);
        return message;
    };

    /**
     * Creates a plain object from a TypingMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof TypingMessage
     * @static
     * @param {TypingMessage} message TypingMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    TypingMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.targetUserId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.targetUserId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.groupId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.groupId = options.longs === String ? "0" : 0;
            object.isTyping = false;
        }
        if (message.targetUserId != null && message.hasOwnProperty("targetUserId"))
            if (typeof message.targetUserId === "number")
                object.targetUserId = options.longs === String ? String(message.targetUserId) : message.targetUserId;
            else
                object.targetUserId = options.longs === String ? $util.Long.prototype.toString.call(message.targetUserId) : options.longs === Number ? new $util.LongBits(message.targetUserId.low >>> 0, message.targetUserId.high >>> 0).toNumber() : message.targetUserId;
        if (message.groupId != null && message.hasOwnProperty("groupId"))
            if (typeof message.groupId === "number")
                object.groupId = options.longs === String ? String(message.groupId) : message.groupId;
            else
                object.groupId = options.longs === String ? $util.Long.prototype.toString.call(message.groupId) : options.longs === Number ? new $util.LongBits(message.groupId.low >>> 0, message.groupId.high >>> 0).toNumber() : message.groupId;
        if (message.isTyping != null && message.hasOwnProperty("isTyping"))
            object.isTyping = message.isTyping;
        return object;
    };

    /**
     * Converts this TypingMessage to JSON.
     * @function toJSON
     * @memberof TypingMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    TypingMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for TypingMessage
     * @function getTypeUrl
     * @memberof TypingMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    TypingMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/TypingMessage";
    };

    return TypingMessage;
})();

export const BadgeUpdateMessage = $root.BadgeUpdateMessage = (() => {

    /**
     * Properties of a BadgeUpdateMessage.
     * @exports IBadgeUpdateMessage
     * @interface IBadgeUpdateMessage
     * @property {number|null} [unreadCount] BadgeUpdateMessage unreadCount
     * @property {Array.<IConversationBadge>|null} [conversationBadges] BadgeUpdateMessage conversationBadges
     * @property {Array.<IMenuBadge>|null} [menuBadges] BadgeUpdateMessage menuBadges
     */

    /**
     * Constructs a new BadgeUpdateMessage.
     * @exports BadgeUpdateMessage
     * @classdesc Represents a BadgeUpdateMessage.
     * @implements IBadgeUpdateMessage
     * @constructor
     * @param {IBadgeUpdateMessage=} [properties] Properties to set
     */
    function BadgeUpdateMessage(properties) {
        this.conversationBadges = [];
        this.menuBadges = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * BadgeUpdateMessage unreadCount.
     * @member {number} unreadCount
     * @memberof BadgeUpdateMessage
     * @instance
     */
    BadgeUpdateMessage.prototype.unreadCount = 0;

    /**
     * BadgeUpdateMessage conversationBadges.
     * @member {Array.<IConversationBadge>} conversationBadges
     * @memberof BadgeUpdateMessage
     * @instance
     */
    BadgeUpdateMessage.prototype.conversationBadges = $util.emptyArray;

    /**
     * BadgeUpdateMessage menuBadges.
     * @member {Array.<IMenuBadge>} menuBadges
     * @memberof BadgeUpdateMessage
     * @instance
     */
    BadgeUpdateMessage.prototype.menuBadges = $util.emptyArray;

    /**
     * Creates a new BadgeUpdateMessage instance using the specified properties.
     * @function create
     * @memberof BadgeUpdateMessage
     * @static
     * @param {IBadgeUpdateMessage=} [properties] Properties to set
     * @returns {BadgeUpdateMessage} BadgeUpdateMessage instance
     */
    BadgeUpdateMessage.create = function create(properties) {
        return new BadgeUpdateMessage(properties);
    };

    /**
     * Encodes the specified BadgeUpdateMessage message. Does not implicitly {@link BadgeUpdateMessage.verify|verify} messages.
     * @function encode
     * @memberof BadgeUpdateMessage
     * @static
     * @param {IBadgeUpdateMessage} message BadgeUpdateMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    BadgeUpdateMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.unreadCount != null && Object.hasOwnProperty.call(message, "unreadCount"))
            writer.uint32(/* id 1, wireType 0 =*/8).int32(message.unreadCount);
        if (message.conversationBadges != null && message.conversationBadges.length)
            for (let i = 0; i < message.conversationBadges.length; ++i)
                $root.ConversationBadge.encode(message.conversationBadges[i], writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
        if (message.menuBadges != null && message.menuBadges.length)
            for (let i = 0; i < message.menuBadges.length; ++i)
                $root.MenuBadge.encode(message.menuBadges[i], writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
        return writer;
    };

    /**
     * Encodes the specified BadgeUpdateMessage message, length delimited. Does not implicitly {@link BadgeUpdateMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof BadgeUpdateMessage
     * @static
     * @param {IBadgeUpdateMessage} message BadgeUpdateMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    BadgeUpdateMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a BadgeUpdateMessage message from the specified reader or buffer.
     * @function decode
     * @memberof BadgeUpdateMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {BadgeUpdateMessage} BadgeUpdateMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    BadgeUpdateMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.BadgeUpdateMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.unreadCount = reader.int32();
                    break;
                }
            case 2: {
                    if (!(message.conversationBadges && message.conversationBadges.length))
                        message.conversationBadges = [];
                    message.conversationBadges.push($root.ConversationBadge.decode(reader, reader.uint32()));
                    break;
                }
            case 3: {
                    if (!(message.menuBadges && message.menuBadges.length))
                        message.menuBadges = [];
                    message.menuBadges.push($root.MenuBadge.decode(reader, reader.uint32()));
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a BadgeUpdateMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof BadgeUpdateMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {BadgeUpdateMessage} BadgeUpdateMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    BadgeUpdateMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a BadgeUpdateMessage message.
     * @function verify
     * @memberof BadgeUpdateMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    BadgeUpdateMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.unreadCount != null && message.hasOwnProperty("unreadCount"))
            if (!$util.isInteger(message.unreadCount))
                return "unreadCount: integer expected";
        if (message.conversationBadges != null && message.hasOwnProperty("conversationBadges")) {
            if (!Array.isArray(message.conversationBadges))
                return "conversationBadges: array expected";
            for (let i = 0; i < message.conversationBadges.length; ++i) {
                let error = $root.ConversationBadge.verify(message.conversationBadges[i]);
                if (error)
                    return "conversationBadges." + error;
            }
        }
        if (message.menuBadges != null && message.hasOwnProperty("menuBadges")) {
            if (!Array.isArray(message.menuBadges))
                return "menuBadges: array expected";
            for (let i = 0; i < message.menuBadges.length; ++i) {
                let error = $root.MenuBadge.verify(message.menuBadges[i]);
                if (error)
                    return "menuBadges." + error;
            }
        }
        return null;
    };

    /**
     * Creates a BadgeUpdateMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof BadgeUpdateMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {BadgeUpdateMessage} BadgeUpdateMessage
     */
    BadgeUpdateMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.BadgeUpdateMessage)
            return object;
        let message = new $root.BadgeUpdateMessage();
        if (object.unreadCount != null)
            message.unreadCount = object.unreadCount | 0;
        if (object.conversationBadges) {
            if (!Array.isArray(object.conversationBadges))
                throw TypeError(".BadgeUpdateMessage.conversationBadges: array expected");
            message.conversationBadges = [];
            for (let i = 0; i < object.conversationBadges.length; ++i) {
                if (typeof object.conversationBadges[i] !== "object")
                    throw TypeError(".BadgeUpdateMessage.conversationBadges: object expected");
                message.conversationBadges[i] = $root.ConversationBadge.fromObject(object.conversationBadges[i]);
            }
        }
        if (object.menuBadges) {
            if (!Array.isArray(object.menuBadges))
                throw TypeError(".BadgeUpdateMessage.menuBadges: array expected");
            message.menuBadges = [];
            for (let i = 0; i < object.menuBadges.length; ++i) {
                if (typeof object.menuBadges[i] !== "object")
                    throw TypeError(".BadgeUpdateMessage.menuBadges: object expected");
                message.menuBadges[i] = $root.MenuBadge.fromObject(object.menuBadges[i]);
            }
        }
        return message;
    };

    /**
     * Creates a plain object from a BadgeUpdateMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof BadgeUpdateMessage
     * @static
     * @param {BadgeUpdateMessage} message BadgeUpdateMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    BadgeUpdateMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults) {
            object.conversationBadges = [];
            object.menuBadges = [];
        }
        if (options.defaults)
            object.unreadCount = 0;
        if (message.unreadCount != null && message.hasOwnProperty("unreadCount"))
            object.unreadCount = message.unreadCount;
        if (message.conversationBadges && message.conversationBadges.length) {
            object.conversationBadges = [];
            for (let j = 0; j < message.conversationBadges.length; ++j)
                object.conversationBadges[j] = $root.ConversationBadge.toObject(message.conversationBadges[j], options);
        }
        if (message.menuBadges && message.menuBadges.length) {
            object.menuBadges = [];
            for (let j = 0; j < message.menuBadges.length; ++j)
                object.menuBadges[j] = $root.MenuBadge.toObject(message.menuBadges[j], options);
        }
        return object;
    };

    /**
     * Converts this BadgeUpdateMessage to JSON.
     * @function toJSON
     * @memberof BadgeUpdateMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    BadgeUpdateMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for BadgeUpdateMessage
     * @function getTypeUrl
     * @memberof BadgeUpdateMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    BadgeUpdateMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/BadgeUpdateMessage";
    };

    return BadgeUpdateMessage;
})();

export const ConversationBadge = $root.ConversationBadge = (() => {

    /**
     * Properties of a ConversationBadge.
     * @exports IConversationBadge
     * @interface IConversationBadge
     * @property {number|Long|null} [conversationId] ConversationBadge conversationId
     * @property {number|null} [unreadCount] ConversationBadge unreadCount
     */

    /**
     * Constructs a new ConversationBadge.
     * @exports ConversationBadge
     * @classdesc Represents a ConversationBadge.
     * @implements IConversationBadge
     * @constructor
     * @param {IConversationBadge=} [properties] Properties to set
     */
    function ConversationBadge(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * ConversationBadge conversationId.
     * @member {number|Long} conversationId
     * @memberof ConversationBadge
     * @instance
     */
    ConversationBadge.prototype.conversationId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * ConversationBadge unreadCount.
     * @member {number} unreadCount
     * @memberof ConversationBadge
     * @instance
     */
    ConversationBadge.prototype.unreadCount = 0;

    /**
     * Creates a new ConversationBadge instance using the specified properties.
     * @function create
     * @memberof ConversationBadge
     * @static
     * @param {IConversationBadge=} [properties] Properties to set
     * @returns {ConversationBadge} ConversationBadge instance
     */
    ConversationBadge.create = function create(properties) {
        return new ConversationBadge(properties);
    };

    /**
     * Encodes the specified ConversationBadge message. Does not implicitly {@link ConversationBadge.verify|verify} messages.
     * @function encode
     * @memberof ConversationBadge
     * @static
     * @param {IConversationBadge} message ConversationBadge message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ConversationBadge.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.conversationId != null && Object.hasOwnProperty.call(message, "conversationId"))
            writer.uint32(/* id 1, wireType 0 =*/8).int64(message.conversationId);
        if (message.unreadCount != null && Object.hasOwnProperty.call(message, "unreadCount"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.unreadCount);
        return writer;
    };

    /**
     * Encodes the specified ConversationBadge message, length delimited. Does not implicitly {@link ConversationBadge.verify|verify} messages.
     * @function encodeDelimited
     * @memberof ConversationBadge
     * @static
     * @param {IConversationBadge} message ConversationBadge message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    ConversationBadge.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a ConversationBadge message from the specified reader or buffer.
     * @function decode
     * @memberof ConversationBadge
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {ConversationBadge} ConversationBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ConversationBadge.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.ConversationBadge();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.conversationId = reader.int64();
                    break;
                }
            case 2: {
                    message.unreadCount = reader.int32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a ConversationBadge message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof ConversationBadge
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {ConversationBadge} ConversationBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    ConversationBadge.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a ConversationBadge message.
     * @function verify
     * @memberof ConversationBadge
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    ConversationBadge.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.conversationId != null && message.hasOwnProperty("conversationId"))
            if (!$util.isInteger(message.conversationId) && !(message.conversationId && $util.isInteger(message.conversationId.low) && $util.isInteger(message.conversationId.high)))
                return "conversationId: integer|Long expected";
        if (message.unreadCount != null && message.hasOwnProperty("unreadCount"))
            if (!$util.isInteger(message.unreadCount))
                return "unreadCount: integer expected";
        return null;
    };

    /**
     * Creates a ConversationBadge message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof ConversationBadge
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {ConversationBadge} ConversationBadge
     */
    ConversationBadge.fromObject = function fromObject(object) {
        if (object instanceof $root.ConversationBadge)
            return object;
        let message = new $root.ConversationBadge();
        if (object.conversationId != null)
            if ($util.Long)
                (message.conversationId = $util.Long.fromValue(object.conversationId)).unsigned = false;
            else if (typeof object.conversationId === "string")
                message.conversationId = parseInt(object.conversationId, 10);
            else if (typeof object.conversationId === "number")
                message.conversationId = object.conversationId;
            else if (typeof object.conversationId === "object")
                message.conversationId = new $util.LongBits(object.conversationId.low >>> 0, object.conversationId.high >>> 0).toNumber();
        if (object.unreadCount != null)
            message.unreadCount = object.unreadCount | 0;
        return message;
    };

    /**
     * Creates a plain object from a ConversationBadge message. Also converts values to other types if specified.
     * @function toObject
     * @memberof ConversationBadge
     * @static
     * @param {ConversationBadge} message ConversationBadge
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    ConversationBadge.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.conversationId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.conversationId = options.longs === String ? "0" : 0;
            object.unreadCount = 0;
        }
        if (message.conversationId != null && message.hasOwnProperty("conversationId"))
            if (typeof message.conversationId === "number")
                object.conversationId = options.longs === String ? String(message.conversationId) : message.conversationId;
            else
                object.conversationId = options.longs === String ? $util.Long.prototype.toString.call(message.conversationId) : options.longs === Number ? new $util.LongBits(message.conversationId.low >>> 0, message.conversationId.high >>> 0).toNumber() : message.conversationId;
        if (message.unreadCount != null && message.hasOwnProperty("unreadCount"))
            object.unreadCount = message.unreadCount;
        return object;
    };

    /**
     * Converts this ConversationBadge to JSON.
     * @function toJSON
     * @memberof ConversationBadge
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    ConversationBadge.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for ConversationBadge
     * @function getTypeUrl
     * @memberof ConversationBadge
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    ConversationBadge.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/ConversationBadge";
    };

    return ConversationBadge;
})();

export const MenuBadge = $root.MenuBadge = (() => {

    /**
     * Properties of a MenuBadge.
     * @exports IMenuBadge
     * @interface IMenuBadge
     * @property {string|null} [menuId] MenuBadge menuId
     * @property {number|null} [badgeCount] MenuBadge badgeCount
     */

    /**
     * Constructs a new MenuBadge.
     * @exports MenuBadge
     * @classdesc Represents a MenuBadge.
     * @implements IMenuBadge
     * @constructor
     * @param {IMenuBadge=} [properties] Properties to set
     */
    function MenuBadge(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * MenuBadge menuId.
     * @member {string} menuId
     * @memberof MenuBadge
     * @instance
     */
    MenuBadge.prototype.menuId = "";

    /**
     * MenuBadge badgeCount.
     * @member {number} badgeCount
     * @memberof MenuBadge
     * @instance
     */
    MenuBadge.prototype.badgeCount = 0;

    /**
     * Creates a new MenuBadge instance using the specified properties.
     * @function create
     * @memberof MenuBadge
     * @static
     * @param {IMenuBadge=} [properties] Properties to set
     * @returns {MenuBadge} MenuBadge instance
     */
    MenuBadge.create = function create(properties) {
        return new MenuBadge(properties);
    };

    /**
     * Encodes the specified MenuBadge message. Does not implicitly {@link MenuBadge.verify|verify} messages.
     * @function encode
     * @memberof MenuBadge
     * @static
     * @param {IMenuBadge} message MenuBadge message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MenuBadge.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.menuId != null && Object.hasOwnProperty.call(message, "menuId"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.menuId);
        if (message.badgeCount != null && Object.hasOwnProperty.call(message, "badgeCount"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.badgeCount);
        return writer;
    };

    /**
     * Encodes the specified MenuBadge message, length delimited. Does not implicitly {@link MenuBadge.verify|verify} messages.
     * @function encodeDelimited
     * @memberof MenuBadge
     * @static
     * @param {IMenuBadge} message MenuBadge message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    MenuBadge.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a MenuBadge message from the specified reader or buffer.
     * @function decode
     * @memberof MenuBadge
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {MenuBadge} MenuBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MenuBadge.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.MenuBadge();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.menuId = reader.string();
                    break;
                }
            case 2: {
                    message.badgeCount = reader.int32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a MenuBadge message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof MenuBadge
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {MenuBadge} MenuBadge
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    MenuBadge.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a MenuBadge message.
     * @function verify
     * @memberof MenuBadge
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    MenuBadge.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.menuId != null && message.hasOwnProperty("menuId"))
            if (!$util.isString(message.menuId))
                return "menuId: string expected";
        if (message.badgeCount != null && message.hasOwnProperty("badgeCount"))
            if (!$util.isInteger(message.badgeCount))
                return "badgeCount: integer expected";
        return null;
    };

    /**
     * Creates a MenuBadge message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof MenuBadge
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {MenuBadge} MenuBadge
     */
    MenuBadge.fromObject = function fromObject(object) {
        if (object instanceof $root.MenuBadge)
            return object;
        let message = new $root.MenuBadge();
        if (object.menuId != null)
            message.menuId = String(object.menuId);
        if (object.badgeCount != null)
            message.badgeCount = object.badgeCount | 0;
        return message;
    };

    /**
     * Creates a plain object from a MenuBadge message. Also converts values to other types if specified.
     * @function toObject
     * @memberof MenuBadge
     * @static
     * @param {MenuBadge} message MenuBadge
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    MenuBadge.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.menuId = "";
            object.badgeCount = 0;
        }
        if (message.menuId != null && message.hasOwnProperty("menuId"))
            object.menuId = message.menuId;
        if (message.badgeCount != null && message.hasOwnProperty("badgeCount"))
            object.badgeCount = message.badgeCount;
        return object;
    };

    /**
     * Converts this MenuBadge to JSON.
     * @function toJSON
     * @memberof MenuBadge
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    MenuBadge.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for MenuBadge
     * @function getTypeUrl
     * @memberof MenuBadge
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    MenuBadge.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/MenuBadge";
    };

    return MenuBadge;
})();

export const CallSignalMessage = $root.CallSignalMessage = (() => {

    /**
     * Properties of a CallSignalMessage.
     * @exports ICallSignalMessage
     * @interface ICallSignalMessage
     * @property {string|null} [callId] CallSignalMessage callId
     * @property {number|null} [callType] CallSignalMessage callType
     * @property {number|null} [signalType] CallSignalMessage signalType
     * @property {number|Long|null} [callerId] CallSignalMessage callerId
     * @property {number|Long|null} [calleeId] CallSignalMessage calleeId
     * @property {string|null} [rejectReason] CallSignalMessage rejectReason
     * @property {string|null} [extraData] CallSignalMessage extraData
     */

    /**
     * Constructs a new CallSignalMessage.
     * @exports CallSignalMessage
     * @classdesc Represents a CallSignalMessage.
     * @implements ICallSignalMessage
     * @constructor
     * @param {ICallSignalMessage=} [properties] Properties to set
     */
    function CallSignalMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * CallSignalMessage callId.
     * @member {string} callId
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.callId = "";

    /**
     * CallSignalMessage callType.
     * @member {number} callType
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.callType = 0;

    /**
     * CallSignalMessage signalType.
     * @member {number} signalType
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.signalType = 0;

    /**
     * CallSignalMessage callerId.
     * @member {number|Long} callerId
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.callerId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * CallSignalMessage calleeId.
     * @member {number|Long} calleeId
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.calleeId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * CallSignalMessage rejectReason.
     * @member {string} rejectReason
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.rejectReason = "";

    /**
     * CallSignalMessage extraData.
     * @member {string} extraData
     * @memberof CallSignalMessage
     * @instance
     */
    CallSignalMessage.prototype.extraData = "";

    /**
     * Creates a new CallSignalMessage instance using the specified properties.
     * @function create
     * @memberof CallSignalMessage
     * @static
     * @param {ICallSignalMessage=} [properties] Properties to set
     * @returns {CallSignalMessage} CallSignalMessage instance
     */
    CallSignalMessage.create = function create(properties) {
        return new CallSignalMessage(properties);
    };

    /**
     * Encodes the specified CallSignalMessage message. Does not implicitly {@link CallSignalMessage.verify|verify} messages.
     * @function encode
     * @memberof CallSignalMessage
     * @static
     * @param {ICallSignalMessage} message CallSignalMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    CallSignalMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.callId != null && Object.hasOwnProperty.call(message, "callId"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.callId);
        if (message.callType != null && Object.hasOwnProperty.call(message, "callType"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.callType);
        if (message.signalType != null && Object.hasOwnProperty.call(message, "signalType"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.signalType);
        if (message.callerId != null && Object.hasOwnProperty.call(message, "callerId"))
            writer.uint32(/* id 4, wireType 0 =*/32).int64(message.callerId);
        if (message.calleeId != null && Object.hasOwnProperty.call(message, "calleeId"))
            writer.uint32(/* id 5, wireType 0 =*/40).int64(message.calleeId);
        if (message.rejectReason != null && Object.hasOwnProperty.call(message, "rejectReason"))
            writer.uint32(/* id 6, wireType 2 =*/50).string(message.rejectReason);
        if (message.extraData != null && Object.hasOwnProperty.call(message, "extraData"))
            writer.uint32(/* id 7, wireType 2 =*/58).string(message.extraData);
        return writer;
    };

    /**
     * Encodes the specified CallSignalMessage message, length delimited. Does not implicitly {@link CallSignalMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof CallSignalMessage
     * @static
     * @param {ICallSignalMessage} message CallSignalMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    CallSignalMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a CallSignalMessage message from the specified reader or buffer.
     * @function decode
     * @memberof CallSignalMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {CallSignalMessage} CallSignalMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    CallSignalMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.CallSignalMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.callId = reader.string();
                    break;
                }
            case 2: {
                    message.callType = reader.int32();
                    break;
                }
            case 3: {
                    message.signalType = reader.int32();
                    break;
                }
            case 4: {
                    message.callerId = reader.int64();
                    break;
                }
            case 5: {
                    message.calleeId = reader.int64();
                    break;
                }
            case 6: {
                    message.rejectReason = reader.string();
                    break;
                }
            case 7: {
                    message.extraData = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a CallSignalMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof CallSignalMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {CallSignalMessage} CallSignalMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    CallSignalMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a CallSignalMessage message.
     * @function verify
     * @memberof CallSignalMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    CallSignalMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.callId != null && message.hasOwnProperty("callId"))
            if (!$util.isString(message.callId))
                return "callId: string expected";
        if (message.callType != null && message.hasOwnProperty("callType"))
            if (!$util.isInteger(message.callType))
                return "callType: integer expected";
        if (message.signalType != null && message.hasOwnProperty("signalType"))
            if (!$util.isInteger(message.signalType))
                return "signalType: integer expected";
        if (message.callerId != null && message.hasOwnProperty("callerId"))
            if (!$util.isInteger(message.callerId) && !(message.callerId && $util.isInteger(message.callerId.low) && $util.isInteger(message.callerId.high)))
                return "callerId: integer|Long expected";
        if (message.calleeId != null && message.hasOwnProperty("calleeId"))
            if (!$util.isInteger(message.calleeId) && !(message.calleeId && $util.isInteger(message.calleeId.low) && $util.isInteger(message.calleeId.high)))
                return "calleeId: integer|Long expected";
        if (message.rejectReason != null && message.hasOwnProperty("rejectReason"))
            if (!$util.isString(message.rejectReason))
                return "rejectReason: string expected";
        if (message.extraData != null && message.hasOwnProperty("extraData"))
            if (!$util.isString(message.extraData))
                return "extraData: string expected";
        return null;
    };

    /**
     * Creates a CallSignalMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof CallSignalMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {CallSignalMessage} CallSignalMessage
     */
    CallSignalMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.CallSignalMessage)
            return object;
        let message = new $root.CallSignalMessage();
        if (object.callId != null)
            message.callId = String(object.callId);
        if (object.callType != null)
            message.callType = object.callType | 0;
        if (object.signalType != null)
            message.signalType = object.signalType | 0;
        if (object.callerId != null)
            if ($util.Long)
                (message.callerId = $util.Long.fromValue(object.callerId)).unsigned = false;
            else if (typeof object.callerId === "string")
                message.callerId = parseInt(object.callerId, 10);
            else if (typeof object.callerId === "number")
                message.callerId = object.callerId;
            else if (typeof object.callerId === "object")
                message.callerId = new $util.LongBits(object.callerId.low >>> 0, object.callerId.high >>> 0).toNumber();
        if (object.calleeId != null)
            if ($util.Long)
                (message.calleeId = $util.Long.fromValue(object.calleeId)).unsigned = false;
            else if (typeof object.calleeId === "string")
                message.calleeId = parseInt(object.calleeId, 10);
            else if (typeof object.calleeId === "number")
                message.calleeId = object.calleeId;
            else if (typeof object.calleeId === "object")
                message.calleeId = new $util.LongBits(object.calleeId.low >>> 0, object.calleeId.high >>> 0).toNumber();
        if (object.rejectReason != null)
            message.rejectReason = String(object.rejectReason);
        if (object.extraData != null)
            message.extraData = String(object.extraData);
        return message;
    };

    /**
     * Creates a plain object from a CallSignalMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof CallSignalMessage
     * @static
     * @param {CallSignalMessage} message CallSignalMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    CallSignalMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.callId = "";
            object.callType = 0;
            object.signalType = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.callerId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.callerId = options.longs === String ? "0" : 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.calleeId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.calleeId = options.longs === String ? "0" : 0;
            object.rejectReason = "";
            object.extraData = "";
        }
        if (message.callId != null && message.hasOwnProperty("callId"))
            object.callId = message.callId;
        if (message.callType != null && message.hasOwnProperty("callType"))
            object.callType = message.callType;
        if (message.signalType != null && message.hasOwnProperty("signalType"))
            object.signalType = message.signalType;
        if (message.callerId != null && message.hasOwnProperty("callerId"))
            if (typeof message.callerId === "number")
                object.callerId = options.longs === String ? String(message.callerId) : message.callerId;
            else
                object.callerId = options.longs === String ? $util.Long.prototype.toString.call(message.callerId) : options.longs === Number ? new $util.LongBits(message.callerId.low >>> 0, message.callerId.high >>> 0).toNumber() : message.callerId;
        if (message.calleeId != null && message.hasOwnProperty("calleeId"))
            if (typeof message.calleeId === "number")
                object.calleeId = options.longs === String ? String(message.calleeId) : message.calleeId;
            else
                object.calleeId = options.longs === String ? $util.Long.prototype.toString.call(message.calleeId) : options.longs === Number ? new $util.LongBits(message.calleeId.low >>> 0, message.calleeId.high >>> 0).toNumber() : message.calleeId;
        if (message.rejectReason != null && message.hasOwnProperty("rejectReason"))
            object.rejectReason = message.rejectReason;
        if (message.extraData != null && message.hasOwnProperty("extraData"))
            object.extraData = message.extraData;
        return object;
    };

    /**
     * Converts this CallSignalMessage to JSON.
     * @function toJSON
     * @memberof CallSignalMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    CallSignalMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for CallSignalMessage
     * @function getTypeUrl
     * @memberof CallSignalMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    CallSignalMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/CallSignalMessage";
    };

    return CallSignalMessage;
})();

export const WorkflowNotifyMessage = $root.WorkflowNotifyMessage = (() => {

    /**
     * Properties of a WorkflowNotifyMessage.
     * @exports IWorkflowNotifyMessage
     * @interface IWorkflowNotifyMessage
     * @property {string|null} [processInstanceId] WorkflowNotifyMessage processInstanceId
     * @property {string|null} [processName] WorkflowNotifyMessage processName
     * @property {number|Long|null} [initiatorId] WorkflowNotifyMessage initiatorId
     * @property {string|null} [initiatorName] WorkflowNotifyMessage initiatorName
     * @property {string|null} [content] WorkflowNotifyMessage content
     * @property {Array.<IWorkflowButton>|null} [buttons] WorkflowNotifyMessage buttons
     * @property {number|null} [status] WorkflowNotifyMessage status
     * @property {string|null} [jumpUrl] WorkflowNotifyMessage jumpUrl
     */

    /**
     * Constructs a new WorkflowNotifyMessage.
     * @exports WorkflowNotifyMessage
     * @classdesc Represents a WorkflowNotifyMessage.
     * @implements IWorkflowNotifyMessage
     * @constructor
     * @param {IWorkflowNotifyMessage=} [properties] Properties to set
     */
    function WorkflowNotifyMessage(properties) {
        this.buttons = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * WorkflowNotifyMessage processInstanceId.
     * @member {string} processInstanceId
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.processInstanceId = "";

    /**
     * WorkflowNotifyMessage processName.
     * @member {string} processName
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.processName = "";

    /**
     * WorkflowNotifyMessage initiatorId.
     * @member {number|Long} initiatorId
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.initiatorId = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * WorkflowNotifyMessage initiatorName.
     * @member {string} initiatorName
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.initiatorName = "";

    /**
     * WorkflowNotifyMessage content.
     * @member {string} content
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.content = "";

    /**
     * WorkflowNotifyMessage buttons.
     * @member {Array.<IWorkflowButton>} buttons
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.buttons = $util.emptyArray;

    /**
     * WorkflowNotifyMessage status.
     * @member {number} status
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.status = 0;

    /**
     * WorkflowNotifyMessage jumpUrl.
     * @member {string} jumpUrl
     * @memberof WorkflowNotifyMessage
     * @instance
     */
    WorkflowNotifyMessage.prototype.jumpUrl = "";

    /**
     * Creates a new WorkflowNotifyMessage instance using the specified properties.
     * @function create
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {IWorkflowNotifyMessage=} [properties] Properties to set
     * @returns {WorkflowNotifyMessage} WorkflowNotifyMessage instance
     */
    WorkflowNotifyMessage.create = function create(properties) {
        return new WorkflowNotifyMessage(properties);
    };

    /**
     * Encodes the specified WorkflowNotifyMessage message. Does not implicitly {@link WorkflowNotifyMessage.verify|verify} messages.
     * @function encode
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {IWorkflowNotifyMessage} message WorkflowNotifyMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    WorkflowNotifyMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.processInstanceId != null && Object.hasOwnProperty.call(message, "processInstanceId"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.processInstanceId);
        if (message.processName != null && Object.hasOwnProperty.call(message, "processName"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.processName);
        if (message.initiatorId != null && Object.hasOwnProperty.call(message, "initiatorId"))
            writer.uint32(/* id 3, wireType 0 =*/24).int64(message.initiatorId);
        if (message.initiatorName != null && Object.hasOwnProperty.call(message, "initiatorName"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.initiatorName);
        if (message.content != null && Object.hasOwnProperty.call(message, "content"))
            writer.uint32(/* id 5, wireType 2 =*/42).string(message.content);
        if (message.buttons != null && message.buttons.length)
            for (let i = 0; i < message.buttons.length; ++i)
                $root.WorkflowButton.encode(message.buttons[i], writer.uint32(/* id 6, wireType 2 =*/50).fork()).ldelim();
        if (message.status != null && Object.hasOwnProperty.call(message, "status"))
            writer.uint32(/* id 7, wireType 0 =*/56).int32(message.status);
        if (message.jumpUrl != null && Object.hasOwnProperty.call(message, "jumpUrl"))
            writer.uint32(/* id 8, wireType 2 =*/66).string(message.jumpUrl);
        return writer;
    };

    /**
     * Encodes the specified WorkflowNotifyMessage message, length delimited. Does not implicitly {@link WorkflowNotifyMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {IWorkflowNotifyMessage} message WorkflowNotifyMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    WorkflowNotifyMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a WorkflowNotifyMessage message from the specified reader or buffer.
     * @function decode
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {WorkflowNotifyMessage} WorkflowNotifyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    WorkflowNotifyMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.WorkflowNotifyMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.processInstanceId = reader.string();
                    break;
                }
            case 2: {
                    message.processName = reader.string();
                    break;
                }
            case 3: {
                    message.initiatorId = reader.int64();
                    break;
                }
            case 4: {
                    message.initiatorName = reader.string();
                    break;
                }
            case 5: {
                    message.content = reader.string();
                    break;
                }
            case 6: {
                    if (!(message.buttons && message.buttons.length))
                        message.buttons = [];
                    message.buttons.push($root.WorkflowButton.decode(reader, reader.uint32()));
                    break;
                }
            case 7: {
                    message.status = reader.int32();
                    break;
                }
            case 8: {
                    message.jumpUrl = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a WorkflowNotifyMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {WorkflowNotifyMessage} WorkflowNotifyMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    WorkflowNotifyMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a WorkflowNotifyMessage message.
     * @function verify
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    WorkflowNotifyMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.processInstanceId != null && message.hasOwnProperty("processInstanceId"))
            if (!$util.isString(message.processInstanceId))
                return "processInstanceId: string expected";
        if (message.processName != null && message.hasOwnProperty("processName"))
            if (!$util.isString(message.processName))
                return "processName: string expected";
        if (message.initiatorId != null && message.hasOwnProperty("initiatorId"))
            if (!$util.isInteger(message.initiatorId) && !(message.initiatorId && $util.isInteger(message.initiatorId.low) && $util.isInteger(message.initiatorId.high)))
                return "initiatorId: integer|Long expected";
        if (message.initiatorName != null && message.hasOwnProperty("initiatorName"))
            if (!$util.isString(message.initiatorName))
                return "initiatorName: string expected";
        if (message.content != null && message.hasOwnProperty("content"))
            if (!$util.isString(message.content))
                return "content: string expected";
        if (message.buttons != null && message.hasOwnProperty("buttons")) {
            if (!Array.isArray(message.buttons))
                return "buttons: array expected";
            for (let i = 0; i < message.buttons.length; ++i) {
                let error = $root.WorkflowButton.verify(message.buttons[i]);
                if (error)
                    return "buttons." + error;
            }
        }
        if (message.status != null && message.hasOwnProperty("status"))
            if (!$util.isInteger(message.status))
                return "status: integer expected";
        if (message.jumpUrl != null && message.hasOwnProperty("jumpUrl"))
            if (!$util.isString(message.jumpUrl))
                return "jumpUrl: string expected";
        return null;
    };

    /**
     * Creates a WorkflowNotifyMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {WorkflowNotifyMessage} WorkflowNotifyMessage
     */
    WorkflowNotifyMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.WorkflowNotifyMessage)
            return object;
        let message = new $root.WorkflowNotifyMessage();
        if (object.processInstanceId != null)
            message.processInstanceId = String(object.processInstanceId);
        if (object.processName != null)
            message.processName = String(object.processName);
        if (object.initiatorId != null)
            if ($util.Long)
                (message.initiatorId = $util.Long.fromValue(object.initiatorId)).unsigned = false;
            else if (typeof object.initiatorId === "string")
                message.initiatorId = parseInt(object.initiatorId, 10);
            else if (typeof object.initiatorId === "number")
                message.initiatorId = object.initiatorId;
            else if (typeof object.initiatorId === "object")
                message.initiatorId = new $util.LongBits(object.initiatorId.low >>> 0, object.initiatorId.high >>> 0).toNumber();
        if (object.initiatorName != null)
            message.initiatorName = String(object.initiatorName);
        if (object.content != null)
            message.content = String(object.content);
        if (object.buttons) {
            if (!Array.isArray(object.buttons))
                throw TypeError(".WorkflowNotifyMessage.buttons: array expected");
            message.buttons = [];
            for (let i = 0; i < object.buttons.length; ++i) {
                if (typeof object.buttons[i] !== "object")
                    throw TypeError(".WorkflowNotifyMessage.buttons: object expected");
                message.buttons[i] = $root.WorkflowButton.fromObject(object.buttons[i]);
            }
        }
        if (object.status != null)
            message.status = object.status | 0;
        if (object.jumpUrl != null)
            message.jumpUrl = String(object.jumpUrl);
        return message;
    };

    /**
     * Creates a plain object from a WorkflowNotifyMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {WorkflowNotifyMessage} message WorkflowNotifyMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    WorkflowNotifyMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults)
            object.buttons = [];
        if (options.defaults) {
            object.processInstanceId = "";
            object.processName = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.initiatorId = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.initiatorId = options.longs === String ? "0" : 0;
            object.initiatorName = "";
            object.content = "";
            object.status = 0;
            object.jumpUrl = "";
        }
        if (message.processInstanceId != null && message.hasOwnProperty("processInstanceId"))
            object.processInstanceId = message.processInstanceId;
        if (message.processName != null && message.hasOwnProperty("processName"))
            object.processName = message.processName;
        if (message.initiatorId != null && message.hasOwnProperty("initiatorId"))
            if (typeof message.initiatorId === "number")
                object.initiatorId = options.longs === String ? String(message.initiatorId) : message.initiatorId;
            else
                object.initiatorId = options.longs === String ? $util.Long.prototype.toString.call(message.initiatorId) : options.longs === Number ? new $util.LongBits(message.initiatorId.low >>> 0, message.initiatorId.high >>> 0).toNumber() : message.initiatorId;
        if (message.initiatorName != null && message.hasOwnProperty("initiatorName"))
            object.initiatorName = message.initiatorName;
        if (message.content != null && message.hasOwnProperty("content"))
            object.content = message.content;
        if (message.buttons && message.buttons.length) {
            object.buttons = [];
            for (let j = 0; j < message.buttons.length; ++j)
                object.buttons[j] = $root.WorkflowButton.toObject(message.buttons[j], options);
        }
        if (message.status != null && message.hasOwnProperty("status"))
            object.status = message.status;
        if (message.jumpUrl != null && message.hasOwnProperty("jumpUrl"))
            object.jumpUrl = message.jumpUrl;
        return object;
    };

    /**
     * Converts this WorkflowNotifyMessage to JSON.
     * @function toJSON
     * @memberof WorkflowNotifyMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    WorkflowNotifyMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for WorkflowNotifyMessage
     * @function getTypeUrl
     * @memberof WorkflowNotifyMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    WorkflowNotifyMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/WorkflowNotifyMessage";
    };

    return WorkflowNotifyMessage;
})();

export const WorkflowButton = $root.WorkflowButton = (() => {

    /**
     * Properties of a WorkflowButton.
     * @exports IWorkflowButton
     * @interface IWorkflowButton
     * @property {string|null} [buttonId] WorkflowButton buttonId
     * @property {string|null} [buttonText] WorkflowButton buttonText
     * @property {number|null} [buttonType] WorkflowButton buttonType
     */

    /**
     * Constructs a new WorkflowButton.
     * @exports WorkflowButton
     * @classdesc Represents a WorkflowButton.
     * @implements IWorkflowButton
     * @constructor
     * @param {IWorkflowButton=} [properties] Properties to set
     */
    function WorkflowButton(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * WorkflowButton buttonId.
     * @member {string} buttonId
     * @memberof WorkflowButton
     * @instance
     */
    WorkflowButton.prototype.buttonId = "";

    /**
     * WorkflowButton buttonText.
     * @member {string} buttonText
     * @memberof WorkflowButton
     * @instance
     */
    WorkflowButton.prototype.buttonText = "";

    /**
     * WorkflowButton buttonType.
     * @member {number} buttonType
     * @memberof WorkflowButton
     * @instance
     */
    WorkflowButton.prototype.buttonType = 0;

    /**
     * Creates a new WorkflowButton instance using the specified properties.
     * @function create
     * @memberof WorkflowButton
     * @static
     * @param {IWorkflowButton=} [properties] Properties to set
     * @returns {WorkflowButton} WorkflowButton instance
     */
    WorkflowButton.create = function create(properties) {
        return new WorkflowButton(properties);
    };

    /**
     * Encodes the specified WorkflowButton message. Does not implicitly {@link WorkflowButton.verify|verify} messages.
     * @function encode
     * @memberof WorkflowButton
     * @static
     * @param {IWorkflowButton} message WorkflowButton message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    WorkflowButton.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.buttonId != null && Object.hasOwnProperty.call(message, "buttonId"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.buttonId);
        if (message.buttonText != null && Object.hasOwnProperty.call(message, "buttonText"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.buttonText);
        if (message.buttonType != null && Object.hasOwnProperty.call(message, "buttonType"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.buttonType);
        return writer;
    };

    /**
     * Encodes the specified WorkflowButton message, length delimited. Does not implicitly {@link WorkflowButton.verify|verify} messages.
     * @function encodeDelimited
     * @memberof WorkflowButton
     * @static
     * @param {IWorkflowButton} message WorkflowButton message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    WorkflowButton.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a WorkflowButton message from the specified reader or buffer.
     * @function decode
     * @memberof WorkflowButton
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {WorkflowButton} WorkflowButton
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    WorkflowButton.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.WorkflowButton();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.buttonId = reader.string();
                    break;
                }
            case 2: {
                    message.buttonText = reader.string();
                    break;
                }
            case 3: {
                    message.buttonType = reader.int32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a WorkflowButton message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof WorkflowButton
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {WorkflowButton} WorkflowButton
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    WorkflowButton.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a WorkflowButton message.
     * @function verify
     * @memberof WorkflowButton
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    WorkflowButton.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.buttonId != null && message.hasOwnProperty("buttonId"))
            if (!$util.isString(message.buttonId))
                return "buttonId: string expected";
        if (message.buttonText != null && message.hasOwnProperty("buttonText"))
            if (!$util.isString(message.buttonText))
                return "buttonText: string expected";
        if (message.buttonType != null && message.hasOwnProperty("buttonType"))
            if (!$util.isInteger(message.buttonType))
                return "buttonType: integer expected";
        return null;
    };

    /**
     * Creates a WorkflowButton message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof WorkflowButton
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {WorkflowButton} WorkflowButton
     */
    WorkflowButton.fromObject = function fromObject(object) {
        if (object instanceof $root.WorkflowButton)
            return object;
        let message = new $root.WorkflowButton();
        if (object.buttonId != null)
            message.buttonId = String(object.buttonId);
        if (object.buttonText != null)
            message.buttonText = String(object.buttonText);
        if (object.buttonType != null)
            message.buttonType = object.buttonType | 0;
        return message;
    };

    /**
     * Creates a plain object from a WorkflowButton message. Also converts values to other types if specified.
     * @function toObject
     * @memberof WorkflowButton
     * @static
     * @param {WorkflowButton} message WorkflowButton
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    WorkflowButton.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.buttonId = "";
            object.buttonText = "";
            object.buttonType = 0;
        }
        if (message.buttonId != null && message.hasOwnProperty("buttonId"))
            object.buttonId = message.buttonId;
        if (message.buttonText != null && message.hasOwnProperty("buttonText"))
            object.buttonText = message.buttonText;
        if (message.buttonType != null && message.hasOwnProperty("buttonType"))
            object.buttonType = message.buttonType;
        return object;
    };

    /**
     * Converts this WorkflowButton to JSON.
     * @function toJSON
     * @memberof WorkflowButton
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    WorkflowButton.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for WorkflowButton
     * @function getTypeUrl
     * @memberof WorkflowButton
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    WorkflowButton.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/WorkflowButton";
    };

    return WorkflowButton;
})();

export const TodoReminderMessage = $root.TodoReminderMessage = (() => {

    /**
     * Properties of a TodoReminderMessage.
     * @exports ITodoReminderMessage
     * @interface ITodoReminderMessage
     * @property {string|null} [todoId] TodoReminderMessage todoId
     * @property {string|null} [title] TodoReminderMessage title
     * @property {string|null} [content] TodoReminderMessage content
     * @property {number|Long|null} [dueTime] TodoReminderMessage dueTime
     * @property {number|null} [reminderType] TodoReminderMessage reminderType
     * @property {string|null} [jumpUrl] TodoReminderMessage jumpUrl
     * @property {number|null} [status] TodoReminderMessage status
     */

    /**
     * Constructs a new TodoReminderMessage.
     * @exports TodoReminderMessage
     * @classdesc Represents a TodoReminderMessage.
     * @implements ITodoReminderMessage
     * @constructor
     * @param {ITodoReminderMessage=} [properties] Properties to set
     */
    function TodoReminderMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * TodoReminderMessage todoId.
     * @member {string} todoId
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.todoId = "";

    /**
     * TodoReminderMessage title.
     * @member {string} title
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.title = "";

    /**
     * TodoReminderMessage content.
     * @member {string} content
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.content = "";

    /**
     * TodoReminderMessage dueTime.
     * @member {number|Long} dueTime
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.dueTime = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

    /**
     * TodoReminderMessage reminderType.
     * @member {number} reminderType
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.reminderType = 0;

    /**
     * TodoReminderMessage jumpUrl.
     * @member {string} jumpUrl
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.jumpUrl = "";

    /**
     * TodoReminderMessage status.
     * @member {number} status
     * @memberof TodoReminderMessage
     * @instance
     */
    TodoReminderMessage.prototype.status = 0;

    /**
     * Creates a new TodoReminderMessage instance using the specified properties.
     * @function create
     * @memberof TodoReminderMessage
     * @static
     * @param {ITodoReminderMessage=} [properties] Properties to set
     * @returns {TodoReminderMessage} TodoReminderMessage instance
     */
    TodoReminderMessage.create = function create(properties) {
        return new TodoReminderMessage(properties);
    };

    /**
     * Encodes the specified TodoReminderMessage message. Does not implicitly {@link TodoReminderMessage.verify|verify} messages.
     * @function encode
     * @memberof TodoReminderMessage
     * @static
     * @param {ITodoReminderMessage} message TodoReminderMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TodoReminderMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.todoId != null && Object.hasOwnProperty.call(message, "todoId"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.todoId);
        if (message.title != null && Object.hasOwnProperty.call(message, "title"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.title);
        if (message.content != null && Object.hasOwnProperty.call(message, "content"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.content);
        if (message.dueTime != null && Object.hasOwnProperty.call(message, "dueTime"))
            writer.uint32(/* id 4, wireType 0 =*/32).int64(message.dueTime);
        if (message.reminderType != null && Object.hasOwnProperty.call(message, "reminderType"))
            writer.uint32(/* id 5, wireType 0 =*/40).int32(message.reminderType);
        if (message.jumpUrl != null && Object.hasOwnProperty.call(message, "jumpUrl"))
            writer.uint32(/* id 6, wireType 2 =*/50).string(message.jumpUrl);
        if (message.status != null && Object.hasOwnProperty.call(message, "status"))
            writer.uint32(/* id 7, wireType 0 =*/56).int32(message.status);
        return writer;
    };

    /**
     * Encodes the specified TodoReminderMessage message, length delimited. Does not implicitly {@link TodoReminderMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof TodoReminderMessage
     * @static
     * @param {ITodoReminderMessage} message TodoReminderMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    TodoReminderMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a TodoReminderMessage message from the specified reader or buffer.
     * @function decode
     * @memberof TodoReminderMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {TodoReminderMessage} TodoReminderMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TodoReminderMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.TodoReminderMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.todoId = reader.string();
                    break;
                }
            case 2: {
                    message.title = reader.string();
                    break;
                }
            case 3: {
                    message.content = reader.string();
                    break;
                }
            case 4: {
                    message.dueTime = reader.int64();
                    break;
                }
            case 5: {
                    message.reminderType = reader.int32();
                    break;
                }
            case 6: {
                    message.jumpUrl = reader.string();
                    break;
                }
            case 7: {
                    message.status = reader.int32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a TodoReminderMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof TodoReminderMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {TodoReminderMessage} TodoReminderMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    TodoReminderMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a TodoReminderMessage message.
     * @function verify
     * @memberof TodoReminderMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    TodoReminderMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.todoId != null && message.hasOwnProperty("todoId"))
            if (!$util.isString(message.todoId))
                return "todoId: string expected";
        if (message.title != null && message.hasOwnProperty("title"))
            if (!$util.isString(message.title))
                return "title: string expected";
        if (message.content != null && message.hasOwnProperty("content"))
            if (!$util.isString(message.content))
                return "content: string expected";
        if (message.dueTime != null && message.hasOwnProperty("dueTime"))
            if (!$util.isInteger(message.dueTime) && !(message.dueTime && $util.isInteger(message.dueTime.low) && $util.isInteger(message.dueTime.high)))
                return "dueTime: integer|Long expected";
        if (message.reminderType != null && message.hasOwnProperty("reminderType"))
            if (!$util.isInteger(message.reminderType))
                return "reminderType: integer expected";
        if (message.jumpUrl != null && message.hasOwnProperty("jumpUrl"))
            if (!$util.isString(message.jumpUrl))
                return "jumpUrl: string expected";
        if (message.status != null && message.hasOwnProperty("status"))
            if (!$util.isInteger(message.status))
                return "status: integer expected";
        return null;
    };

    /**
     * Creates a TodoReminderMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof TodoReminderMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {TodoReminderMessage} TodoReminderMessage
     */
    TodoReminderMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.TodoReminderMessage)
            return object;
        let message = new $root.TodoReminderMessage();
        if (object.todoId != null)
            message.todoId = String(object.todoId);
        if (object.title != null)
            message.title = String(object.title);
        if (object.content != null)
            message.content = String(object.content);
        if (object.dueTime != null)
            if ($util.Long)
                (message.dueTime = $util.Long.fromValue(object.dueTime)).unsigned = false;
            else if (typeof object.dueTime === "string")
                message.dueTime = parseInt(object.dueTime, 10);
            else if (typeof object.dueTime === "number")
                message.dueTime = object.dueTime;
            else if (typeof object.dueTime === "object")
                message.dueTime = new $util.LongBits(object.dueTime.low >>> 0, object.dueTime.high >>> 0).toNumber();
        if (object.reminderType != null)
            message.reminderType = object.reminderType | 0;
        if (object.jumpUrl != null)
            message.jumpUrl = String(object.jumpUrl);
        if (object.status != null)
            message.status = object.status | 0;
        return message;
    };

    /**
     * Creates a plain object from a TodoReminderMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof TodoReminderMessage
     * @static
     * @param {TodoReminderMessage} message TodoReminderMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    TodoReminderMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.todoId = "";
            object.title = "";
            object.content = "";
            if ($util.Long) {
                let long = new $util.Long(0, 0, false);
                object.dueTime = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.dueTime = options.longs === String ? "0" : 0;
            object.reminderType = 0;
            object.jumpUrl = "";
            object.status = 0;
        }
        if (message.todoId != null && message.hasOwnProperty("todoId"))
            object.todoId = message.todoId;
        if (message.title != null && message.hasOwnProperty("title"))
            object.title = message.title;
        if (message.content != null && message.hasOwnProperty("content"))
            object.content = message.content;
        if (message.dueTime != null && message.hasOwnProperty("dueTime"))
            if (typeof message.dueTime === "number")
                object.dueTime = options.longs === String ? String(message.dueTime) : message.dueTime;
            else
                object.dueTime = options.longs === String ? $util.Long.prototype.toString.call(message.dueTime) : options.longs === Number ? new $util.LongBits(message.dueTime.low >>> 0, message.dueTime.high >>> 0).toNumber() : message.dueTime;
        if (message.reminderType != null && message.hasOwnProperty("reminderType"))
            object.reminderType = message.reminderType;
        if (message.jumpUrl != null && message.hasOwnProperty("jumpUrl"))
            object.jumpUrl = message.jumpUrl;
        if (message.status != null && message.hasOwnProperty("status"))
            object.status = message.status;
        return object;
    };

    /**
     * Converts this TodoReminderMessage to JSON.
     * @function toJSON
     * @memberof TodoReminderMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    TodoReminderMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for TodoReminderMessage
     * @function getTypeUrl
     * @memberof TodoReminderMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    TodoReminderMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/TodoReminderMessage";
    };

    return TodoReminderMessage;
})();

export { $root as default };
