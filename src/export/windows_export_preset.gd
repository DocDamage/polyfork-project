class_name PlayWorldWindowsExportPreset
extends RefCounted

static func text(package_name: String) -> String:
    return """[preset.0]

name=\"Windows Desktop\"
platform=\"Windows Desktop\"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=\"\"
export_filter=\"all_resources\"
include_filter=\"\"
exclude_filter=\"\"
export_path=\"build/%s.exe\"
script_export_mode=2

[preset.0.options]
custom_template/debug=\"\"
custom_template/release=\"\"
debug/export_console_wrapper=1
binary_format/embed_pck=false
binary_format/architecture=\"x86_64\"
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
""" % package_name
