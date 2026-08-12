class_name PlayWorldStableId
extends RefCounted

const UUID_LENGTH := 36
const HYPHEN_POSITIONS := [8, 13, 18, 23]
const HEX := "0123456789abcdef"


static func generate() -> String:
    var crypto := Crypto.new()
    var bytes := crypto.generate_random_bytes(16)
    if bytes.size() != 16:
        push_error("Unable to generate 16 random bytes for a stable UUID.")
        return ""
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    var parts: Array[String] = []
    for index in range(bytes.size()): parts.append("%02x" % bytes[index])
    return "%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s" % parts


static func from_seed(seed: String) -> String:
    if seed.is_empty(): return ""
    var context := HashingContext.new()
    if context.start(HashingContext.HASH_SHA256) != OK: return ""
    if context.update(seed.to_utf8_buffer()) != OK: return ""
    var digest := context.finish().hex_encode()
    if digest.length() < 32: return ""
    return "%s-%s-4%s-8%s-%s" % [digest.substr(0, 8), digest.substr(8, 4), digest.substr(13, 3), digest.substr(17, 3), digest.substr(20, 12)]


static func is_valid(value: String) -> bool:
    if value.length() != UUID_LENGTH or value != value.to_lower(): return false
    for position in HYPHEN_POSITIONS:
        if value[position] != "-": return false
    for index in range(UUID_LENGTH):
        if index in HYPHEN_POSITIONS: continue
        if HEX.find(value[index]) == -1: return false
    if value[14] != "4": return false
    if "89ab".find(value[19]) == -1: return false
    return not is_nil(value)


static func is_nil(value: String) -> bool:
    return value == "00000000-0000-0000-0000-000000000000"
