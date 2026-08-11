class_name PlayWorldThemeFactory
extends RefCounted

const Tokens = preload("res://src/app/theme/ui_tokens.gd")


static func create_theme() -> Theme:
    var theme := Theme.new()
    _configure_base(theme)
    _configure_buttons(theme)
    _configure_panels(theme)
    _configure_inputs(theme)
    return theme


static func _configure_base(theme: Theme) -> void:
    theme.set_color("font_color", "Label", Tokens.TEXT_PRIMARY)
    theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.2))
    theme.set_font_size("font_size", "Label", Tokens.FONT_BODY)
    theme.set_constant("outline_size", "Label", 0)

    theme.set_type_variation("DisplayLabel", "Label")
    theme.set_font_size("font_size", "DisplayLabel", Tokens.FONT_DISPLAY)

    theme.set_type_variation("TitleLabel", "Label")
    theme.set_font_size("font_size", "TitleLabel", Tokens.FONT_TITLE)

    theme.set_type_variation("HeadingLabel", "Label")
    theme.set_font_size("font_size", "HeadingLabel", Tokens.FONT_HEADING)

    theme.set_type_variation("SecondaryLabel", "Label")
    theme.set_color("font_color", "SecondaryLabel", Tokens.TEXT_SECONDARY)

    theme.set_type_variation("CaptionLabel", "Label")
    theme.set_color("font_color", "CaptionLabel", Tokens.TEXT_SECONDARY)
    theme.set_font_size("font_size", "CaptionLabel", Tokens.FONT_CAPTION)


static func _configure_buttons(theme: Theme) -> void:
    theme.set_color("font_color", "Button", Tokens.TEXT_PRIMARY)
    theme.set_color("font_hover_color", "Button", Tokens.TEXT_PRIMARY)
    theme.set_color("font_pressed_color", "Button", Tokens.TEXT_PRIMARY)
    theme.set_color("font_focus_color", "Button", Tokens.TEXT_PRIMARY)
    theme.set_color("font_disabled_color", "Button", Tokens.TEXT_MUTED)
    theme.set_font_size("font_size", "Button", Tokens.FONT_BODY)
    theme.set_constant("outline_size", "Button", 0)
    theme.set_stylebox("normal", "Button", _box(Tokens.SURFACE_2, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("hover", "Button", _box(Tokens.SURFACE_3, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("pressed", "Button", _box(Tokens.SURFACE_ELEVATED, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("focus", "Button", _outline_box(Tokens.FOCUS, Tokens.RADIUS_MEDIUM, 2))
    theme.set_stylebox("disabled", "Button", _box(Tokens.SURFACE_1, Tokens.RADIUS_MEDIUM))

    theme.set_type_variation("PrimaryButton", "Button")
    theme.set_stylebox("normal", "PrimaryButton", _box(Tokens.FOCUS.darkened(0.25), Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("hover", "PrimaryButton", _box(Tokens.FOCUS.darkened(0.12), Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("pressed", "PrimaryButton", _box(Tokens.FOCUS.darkened(0.35), Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("focus", "PrimaryButton", _outline_box(Tokens.TEXT_PRIMARY, Tokens.RADIUS_MEDIUM, 2))

    theme.set_type_variation("CardButton", "Button")
    theme.set_font_size("font_size", "CardButton", Tokens.FONT_HEADING)
    theme.set_stylebox("normal", "CardButton", _box(Tokens.SURFACE_1, Tokens.RADIUS_LARGE))
    theme.set_stylebox("hover", "CardButton", _box(Tokens.SURFACE_2, Tokens.RADIUS_LARGE))
    theme.set_stylebox("pressed", "CardButton", _box(Tokens.SURFACE_3, Tokens.RADIUS_LARGE))
    theme.set_stylebox("focus", "CardButton", _outline_box(Tokens.FOCUS, Tokens.RADIUS_LARGE, 3))

    theme.set_type_variation("ToolButton", "Button")
    theme.set_stylebox("normal", "ToolButton", _box(Tokens.SURFACE_1, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("hover", "ToolButton", _box(Tokens.SURFACE_3, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("pressed", "ToolButton", _box(Tokens.SURFACE_ELEVATED, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("focus", "ToolButton", _outline_box(Tokens.FOCUS, Tokens.RADIUS_MEDIUM, 2))


static func _configure_panels(theme: Theme) -> void:
    theme.set_stylebox("panel", "Panel", _box(Tokens.SURFACE_1, Tokens.RADIUS_LARGE))
    theme.set_stylebox("panel", "PanelContainer", _box(Tokens.SURFACE_1, Tokens.RADIUS_LARGE))

    theme.set_type_variation("ElevatedPanel", "PanelContainer")
    theme.set_stylebox("panel", "ElevatedPanel", _outline_panel(Tokens.SURFACE_2, Tokens.BORDER_SOFT, Tokens.RADIUS_LARGE))

    theme.set_type_variation("DrawerPanel", "PanelContainer")
    theme.set_stylebox("panel", "DrawerPanel", _outline_panel(Tokens.SURFACE_1, Tokens.BORDER_SOFT, Tokens.RADIUS_XL))


static func _configure_inputs(theme: Theme) -> void:
    theme.set_color("font_color", "LineEdit", Tokens.TEXT_PRIMARY)
    theme.set_color("font_placeholder_color", "LineEdit", Tokens.TEXT_MUTED)
    theme.set_font_size("font_size", "LineEdit", Tokens.FONT_BODY)
    theme.set_stylebox("normal", "LineEdit", _outline_panel(Tokens.SURFACE_1, Tokens.BORDER_SOFT, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("focus", "LineEdit", _outline_panel(Tokens.SURFACE_1, Tokens.FOCUS, Tokens.RADIUS_MEDIUM, 2))

    theme.set_color("font_color", "OptionButton", Tokens.TEXT_PRIMARY)
    theme.set_font_size("font_size", "OptionButton", Tokens.FONT_BODY)
    theme.set_stylebox("normal", "OptionButton", _outline_panel(Tokens.SURFACE_1, Tokens.BORDER_SOFT, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("hover", "OptionButton", _outline_panel(Tokens.SURFACE_2, Tokens.BORDER_SOFT, Tokens.RADIUS_MEDIUM))
    theme.set_stylebox("focus", "OptionButton", _outline_panel(Tokens.SURFACE_1, Tokens.FOCUS, Tokens.RADIUS_MEDIUM, 2))


static func _box(color: Color, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = color
    _set_radius(box, radius)
    _set_margins(box, Tokens.SPACE_4, Tokens.SPACE_3)
    return box


static func _outline_box(color: Color, radius: int, width: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0, 0, 0, 0)
    box.border_color = color
    _set_border_width(box, width)
    _set_radius(box, radius)
    _set_margins(box, Tokens.SPACE_4, Tokens.SPACE_3)
    return box


static func _outline_panel(
    background: Color,
    border: Color,
    radius: int,
    width: int = 1
) -> StyleBoxFlat:
    var box := _box(background, radius)
    box.border_color = border
    _set_border_width(box, width)
    return box


static func _set_radius(box: StyleBoxFlat, radius: int) -> void:
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius


static func _set_border_width(box: StyleBoxFlat, width: int) -> void:
    box.border_width_left = width
    box.border_width_top = width
    box.border_width_right = width
    box.border_width_bottom = width


static func _set_margins(box: StyleBoxFlat, horizontal: float, vertical: float) -> void:
    box.content_margin_left = horizontal
    box.content_margin_right = horizontal
    box.content_margin_top = vertical
    box.content_margin_bottom = vertical
