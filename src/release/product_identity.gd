class_name PlayWorldProductIdentity
extends RefCounted

const PRODUCT_NAME := "PlayWorld Studio"
const COMPANY_NAME := "PlayWorld Studio"
const VERSION := "0.1.0"
const CHANNEL := "stable"
const PACKAGE_PREFIX := "PlayWorld-Studio"
const PLATFORM := "Windows"
const ARCHITECTURE := "x86_64"
const GODOT_VERSION := "4.7.1"
const BASE_COMMIT := "91b8b9c39fddda4b80ad5c6101d563245ef3e2d0"

static func version() -> String:
    return str(ProjectSettings.get_setting("application/config/version", VERSION))

static func package_name() -> String:
    return "%s-%s-Windows-x64" % [PACKAGE_PREFIX, version()]

static func summary() -> Dictionary:
    return {
        "product_name": PRODUCT_NAME,
        "company_name": COMPANY_NAME,
        "version": version(),
        "channel": CHANNEL,
        "platform": PLATFORM,
        "architecture": ARCHITECTURE,
        "godot_version": GODOT_VERSION,
        "base_commit": BASE_COMMIT,
        "package_name": package_name(),
    }

static func short_commit() -> String:
    return BASE_COMMIT.substr(0, 12)
