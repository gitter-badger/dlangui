// Written in the D programming language.

/**
This module contains declaration of themes and styles implementation.

Style - style container
Theme - parent for all styles


Synopsis:

----
import dlangui.widgets.styles;

----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.widgets.styles;

private import std.xml;
private import std.string;
private import std.algorithm;

import dlangui.core.types;
import dlangui.graphics.fonts;
import dlangui.graphics.drawbuf;
import dlangui.graphics.resources;

immutable ubyte ALIGN_UNSPECIFIED = 0;
immutable uint COLOR_UNSPECIFIED = 0xFFDEADFF;
/// transparent color constant
immutable uint COLOR_TRANSPARENT = 0xFFFFFFFF;
/// unspecified font size constant - to take parent style property value
immutable ushort FONT_SIZE_UNSPECIFIED = 0xFFFF;
/// unspecified font weight constant - to take parent style property value
immutable ushort FONT_WEIGHT_UNSPECIFIED = 0x0000;
/// unspecified font style constant - to take parent style property value
immutable ubyte FONT_STYLE_UNSPECIFIED = 0xFF;
/// normal font style constant
immutable ubyte FONT_STYLE_NORMAL = 0x00;
/// italic font style constant
immutable ubyte FONT_STYLE_ITALIC = 0x01;
/// use as widget.layout() param to avoid applying of parent size
immutable int SIZE_UNSPECIFIED = int.max;
/// use text flags from parent style
immutable uint TEXT_FLAGS_UNSPECIFIED = uint.max;
/// use text flags from parent widget
immutable uint TEXT_FLAGS_USE_PARENT = uint.max - 1;

/// layout option, to occupy all available place
immutable int FILL_PARENT = int.max - 1;
/// layout option, for size based on content
immutable int WRAP_CONTENT = int.max - 2;
/// to take layout weight from parent
immutable int WEIGHT_UNSPECIFIED = -1;

/// Align option bit constants
enum Align : ubyte {
	/// alignment is not specified
    Unspecified = ALIGN_UNSPECIFIED,
	/// horizontally align to the left of box
    Left = 1,
	/// horizontally align to the right of box
	Right = 2,
	/// horizontally align to the center of box
	HCenter = 1 | 2,
	/// vertically align to the top of box
	Top = 4,
	/// vertically align to the bottom of box
	Bottom = 8,
	/// vertically align to the center of box
	VCenter = 4 | 8,
	/// align to the center of box (VCenter | HCenter)
	Center = VCenter | HCenter,
	/// align to the top left corner of box (Left | Top)
	TopLeft = Left | Top,
}

/// text drawing flag bits
enum TextFlag : uint {
	/// text contains hot key prefixed with & char (e.g. "&File")
	HotKeys = 1,
	/// underline hot key when drawing
	UnderlineHotKeys = 2,
	/// underline hot key when drawing
	UnderlineHotKeysWhenAltPressed = 4,
	/// underline text when drawing
	Underline = 8
}

/// custom drawable attribute container for styles
class DrawableAttribute {
    protected string _id;
    protected string _drawableId;
    protected DrawableRef _drawable;
    protected bool _initialized;
    this(string id, string drawableId) {
        _id = id;
        _drawableId = drawableId;
    }
    @property string id() const { return _id; }
    @property string drawableId() const { return _drawableId; }
    @property void drawableId(string newDrawable) { _drawableId = newDrawable; clear(); }
    @property ref DrawableRef drawable() const {
        if (!_drawable.isNull)
            return (cast(DrawableAttribute)this)._drawable;
        (cast(DrawableAttribute)this)._drawable = drawableCache.get(_id);
        (cast(DrawableAttribute)this)._initialized = true;
        return (cast(DrawableAttribute)this)._drawable;
    }
    void clear() {
        _drawable.clear();
        _initialized = false;
    }
}

/// style properties
class Style {
	protected string _id;
	protected Theme _theme;
	protected Style _parentStyle;
	protected string _parentId;
	protected uint _stateMask;
	protected uint _stateValue;
	protected ubyte _align = Align.TopLeft;
	protected ubyte _fontStyle = FONT_STYLE_UNSPECIFIED;
	protected FontFamily _fontFamily = FontFamily.Unspecified;
	protected ushort _fontSize = FONT_SIZE_UNSPECIFIED;
	protected ushort _fontWeight = FONT_WEIGHT_UNSPECIFIED;
	protected uint _backgroundColor = COLOR_UNSPECIFIED;
	protected uint _textColor = COLOR_UNSPECIFIED;
	protected uint _textFlags = 0;
	protected uint _alpha;
	protected string _fontFace;
	protected string _backgroundImageId;
	protected Rect _padding;
	protected Rect _margins;
    protected int _minWidth = SIZE_UNSPECIFIED;
    protected int _maxWidth = SIZE_UNSPECIFIED;
    protected int _minHeight = SIZE_UNSPECIFIED;
    protected int _maxHeight = SIZE_UNSPECIFIED;
    protected int _layoutWidth = SIZE_UNSPECIFIED;
    protected int _layoutHeight = SIZE_UNSPECIFIED;
    protected int _layoutWeight = WEIGHT_UNSPECIFIED;

	protected Style[] _substates;
	protected Style[] _children;

    protected DrawableAttribute[string] _customDrawables;

	protected FontRef _font;
	protected DrawableRef _backgroundDrawable;

	@property const(Theme) theme() const {
		if (_theme !is null)
			return _theme;
		return currentTheme;
	}

	@property Theme theme() {
		if (_theme !is null)
			return _theme;
		return currentTheme;
	}

	@property string id() const { return _id; }
	@property Style id(string id) {
		this._id = id;
		return this;
	}

	/// access to parent style for this style
	@property const(Style) parentStyle() const {
		if (_parentStyle !is null)
			return _parentStyle;
		if (_parentId !is null && currentTheme !is null)
			return currentTheme.get(_parentId);
		return currentTheme;
	}

	/// access to parent style for this style
	@property Style parentStyle() {
		if (_parentStyle !is null)
			return _parentStyle;
		if (_parentId !is null && currentTheme !is null)
			return currentTheme.get(_parentId);
		return currentTheme;
	}

    @property ref DrawableRef backgroundDrawable() const {
		if (!(cast(Style)this)._backgroundDrawable.isNull)
			return (cast(Style)this)._backgroundDrawable;
        string image = backgroundImageId;
        if (image !is null) {
            (cast(Style)this)._backgroundDrawable = drawableCache.get(image);
        } else {
            uint color = backgroundColor;
            (cast(Style)this)._backgroundDrawable = new SolidFillDrawable(color);
        }
        return (cast(Style)this)._backgroundDrawable;
    }

    /// get custom drawable attribute
    ref DrawableRef customDrawable(string id) {
        if (id in _customDrawables)
            return _customDrawables[id].drawable;
        return parentStyle.customDrawable(id);
    }

    /// get custom drawable attribute
    string customDrawableId(string id) const {
        if (id in _customDrawables)
            return _customDrawables[id].drawableId;
        return parentStyle.customDrawableId(id);
    }

    /// sets custom drawable attribute for style
    Style setCustomDrawable(string id, string resourceId) {
        if (id in _customDrawables)
            _customDrawables[id].drawableId = resourceId;
        else
            _customDrawables[id] = new DrawableAttribute(id, resourceId);
        return this;
    }


    //===================================================
    // font properties

	@property ref FontRef font() const {
		if (!(cast(Style)this)._font.isNull)
			return (cast(Style)this)._font;
		string face = fontFace;
		int size = fontSize;
		ushort weight = fontWeight;
		bool italic = fontItalic;
		FontFamily family = fontFamily;
		(cast(Style)this)._font = FontManager.instance.getFont(size, weight, italic, family, face);
		return (cast(Style)this)._font;
	}

	/// font size
	@property FontFamily fontFamily() const {
        if (_fontFamily != FontFamily.Unspecified)
            return _fontFamily;
        else
            return parentStyle.fontFamily;
	}

	/// font size
	@property string fontFace() const {
        if (_fontFace !is null)
            return _fontFace;
        else
            return parentStyle.fontFace;
	}

	/// font style - italic
	@property bool fontItalic() const {
        if (_fontStyle != FONT_STYLE_UNSPECIFIED)
            return _fontStyle == FONT_STYLE_ITALIC;
        else
            return parentStyle.fontItalic;
	}

	/// font weight
	@property ushort fontWeight() const {
        if (_fontWeight != FONT_WEIGHT_UNSPECIFIED)
            return _fontWeight;
        else
            return parentStyle.fontWeight;
	}

	/// font size
	@property ushort fontSize() const {
        if (_fontSize != FONT_SIZE_UNSPECIFIED)
            return _fontSize;
        else
            return parentStyle.fontSize;
	}

    //===================================================
    // layout parameters: margins / padding

	/// padding
	@property ref const(Rect) padding() const {
		if (_stateMask || _padding.left == SIZE_UNSPECIFIED)
			return parentStyle._padding;
		return _padding;
	}

	/// margins
	@property ref const(Rect) margins() const {
		if (_stateMask || _margins.left == SIZE_UNSPECIFIED)
			return parentStyle._margins;
		return _margins;
	}

	/// alpha (0=opaque .. 255=transparent)
	@property uint alpha() const {
		if (_alpha != COLOR_UNSPECIFIED)
			return _alpha;
		else
			return parentStyle.alpha;
	}
	
	/// text color
	@property uint textColor() const {
        if (_textColor != COLOR_UNSPECIFIED)
            return _textColor;
        else
            return parentStyle.textColor;
	}

	/// text flags
	@property uint textFlags() const {
		if (_textFlags != TEXT_FLAGS_UNSPECIFIED)
			return _textFlags;
		else
			return parentStyle.textFlags;
	}
	
	//===================================================
    // background

	/// background color
	@property uint backgroundColor() const {
        if (_backgroundColor != COLOR_UNSPECIFIED)
            return _backgroundColor;
        else
            return parentStyle.backgroundColor;
	}

	/// font size
	@property string backgroundImageId() const {
        if (_backgroundImageId !is null)
            return _backgroundImageId;
        else
            return parentStyle.backgroundImageId;
	}

    //===================================================
    // size restrictions

	/// minimal width constraint, 0 if limit is not set
	@property uint minWidth() const {
        if (_minWidth != SIZE_UNSPECIFIED)
            return _minWidth;
        else
            return parentStyle.minWidth;
	}
	/// max width constraint, returns SIZE_UNSPECIFIED if limit is not set
	@property uint maxWidth() const {
        if (_maxWidth != SIZE_UNSPECIFIED)
            return _maxWidth;
        else
            return parentStyle.maxWidth;
	}
	/// minimal height constraint, 0 if limit is not set
	@property uint minHeight() const {
        if (_minHeight != SIZE_UNSPECIFIED)
            return _minHeight;
        else
            return parentStyle.minHeight;
	}
	/// max height constraint, SIZE_UNSPECIFIED if limit is not set
	@property uint maxHeight() const {
        if (_maxHeight != SIZE_UNSPECIFIED)
            return _maxHeight;
        else
            return parentStyle.maxHeight;
	}
    /// set min width constraint
    @property Style minWidth(int value) {
        _minWidth = value;
        return this;
    }
    /// set max width constraint
    @property Style maxWidth(int value) {
        _maxWidth = value;
        return this;
    }
    /// set min height constraint
    @property Style minHeight(int value) {
        _minHeight = value;
        return this;
    }
    /// set max height constraint
    @property Style maxHeight(int value) {
        _maxHeight = value;
        return this;
    }


	/// layout width parameter
	@property uint layoutWidth() const {
        if (_layoutWidth != SIZE_UNSPECIFIED)
            return _layoutWidth;
        else
            return parentStyle.layoutWidth;
	}

	/// layout height parameter
	@property uint layoutHeight() const {
        if (_layoutHeight != SIZE_UNSPECIFIED)
            return _layoutHeight;
        else
            return parentStyle.layoutHeight;
	}

	/// layout weight parameter
	@property uint layoutWeight() const {
        if (_layoutWeight != WEIGHT_UNSPECIFIED)
            return _layoutWeight;
        else
            return parentStyle.layoutWeight;
	}

    /// set layout height
    @property Style layoutHeight(int value) {
        _layoutHeight = value;
        return this;
    }
    /// set layout width
    @property Style layoutWidth(int value) {
        _layoutWidth = value;
        return this;
    }
    /// set layout weight
    @property Style layoutWeight(int value) {
        _layoutWeight = value;
        return this;
    }

    //===================================================
    // alignment

	/// get full alignment (both vertical and horizontal)
	@property ubyte alignment() const { 
        if (_align != Align.Unspecified)
            return _align; 
        else
            return parentStyle.alignment;
    }
	/// vertical alignment: Top / VCenter / Bottom
	@property ubyte valign() const { return alignment & Align.VCenter; }
	/// horizontal alignment: Left / HCenter / Right
	@property ubyte halign() const { return alignment & Align.HCenter; }

    /// set alignment
    @property Style alignment(ubyte value) {
        _align = value;
        return this;
    }

	@property Style fontFace(string face) {
		_fontFace = face;
		_font.clear();
		return this;
	}

	@property Style fontFamily(FontFamily family) {
		_fontFamily = family;
		_font.clear();
		return this;
	}

	@property Style fontStyle(ubyte style) {
		_fontStyle = style;
		_font.clear();
		return this;
	}

	@property Style fontWeight(ushort weight) {
		_fontWeight = weight;
		_font.clear();
		return this;
	}

	@property Style fontSize(ushort size) {
		_fontSize = size;
		_font.clear();
		return this;
	}

	@property Style textColor(uint color) {
		_textColor = color;
		return this;
	}

	@property Style alpha(uint alpha) {
		_alpha = alpha;
		return this;
	}
	
	@property Style textFlags(uint flags) {
		_textFlags = flags;
		return this;
	}
	
	@property Style backgroundColor(uint color) {
		_backgroundColor = color;
        _backgroundImageId = null;
		_backgroundDrawable.clear();
		return this;
	}

	@property Style backgroundImageId(string image) {
		_backgroundImageId = image;
		_backgroundDrawable.clear();
		return this;
	}

	@property Style margins(Rect rc) {
		_margins = rc;
		return this;
	}

	Style setMargins(int left, int top, int right, int bottom) {
		_margins.left = left;
		_margins.top = top;
		_margins.right = right;
		_margins.bottom = bottom;
		return this;
	}
	
	@property Style padding(Rect rc) {
		_padding = rc;
		return this;
	}

	Style setPadding(int left, int top, int right, int bottom) {
		_padding.left = left;
		_padding.top = top;
		_padding.right = right;
		_padding.bottom = bottom;
		return this;
	}
	
	debug(resalloc) private static int _instanceCount;
	debug(resalloc) @property static int instanceCount() { return _instanceCount; }

	this(Theme theme, string id) {
		_theme = theme;
		_parentStyle = theme;
		_id = id;
		debug(resalloc) _instanceCount++;
		//Log.d("Created style ", _id, ", count=", ++_instanceCount);
	}


	~this() {
		foreach(ref Style item; _substates) {
			//Log.d("Destroying substate");
			destroy(item);
			item = null;
		}
		_substates.destroy();
		foreach(ref Style item; _children) {
			destroy(item);
			item = null;
		}
		_children.destroy();
		_backgroundDrawable.clear();
		_font.clear();
		debug(resalloc) _instanceCount--;
		//Log.d("Destroyed style ", _id, ", parentId=", _parentId, ", state=", _stateMask, ", count=", --_instanceCount);
	}

	/// create named substyle of this style
	Style createSubstyle(string id) {
		Style child = (_theme !is null ? _theme : currentTheme).createSubstyle(id);
		child._parentStyle = this;
		_children ~= child;
		return child;
	}

	/// create state substyle for this style
	Style createState(uint stateMask = 0, uint stateValue = 0) {
        assert(stateMask != 0);
		debug(styles) Log.d("Creating substate ", stateMask);
		Style child = (_theme !is null ? _theme : currentTheme).createSubstyle(null);
		child._parentStyle = this;
		child._stateMask = stateMask;
		child._stateValue = stateValue;
		child._backgroundColor = COLOR_UNSPECIFIED;
		child._textColor = COLOR_UNSPECIFIED;
		child._textFlags = TEXT_FLAGS_UNSPECIFIED;
		_substates ~= child;
		return child;
	}

	/// find substyle based on widget state (e.g. focused, pressed, ...)
	const(Style) forState(uint state) const {
		if (state == State.Normal)
			return this;
        //Log.d("forState ", state, " styleId=", _id, " substates=", _substates.length);
		if (parentStyle !is null && _substates.length == 0 && parentStyle._substates.length > 0) //id is null && 
			return parentStyle.forState(state);
		foreach(item; _substates) {
			if ((item._stateMask & state) == item._stateValue)
				return item;
		}
		return this; // fallback to current style
	}
	
}

/// Theme - root for style hierarhy.
class Theme : Style {
	protected Style[string] _byId;

	this(string id) {
		super(this, id);
		_parentStyle = null;
		_backgroundColor = 0xFFFFFFFF; // transparent
		_textColor = 0x000000; // black
		_align = Align.TopLeft;
		_fontSize = 14; // TODO: from settings or screen properties / DPI
		_fontStyle = FONT_STYLE_NORMAL;
		_fontWeight = 400;
		//_fontFace = "Arial"; // TODO: from settings
		_fontFace = "Verdana"; // TODO: from settings
        _fontFamily = FontFamily.SansSerif;
        _minHeight = 0;
        _minWidth = 0;
        _layoutWidth = WRAP_CONTENT;
        _layoutHeight = WRAP_CONTENT;
        _layoutWeight = 1;
	}
	
	~this() {
		//Log.d("Theme destructor");
		foreach(ref Style item; _byId) {
			destroy(item);
			item = null;
		}
		_byId.destroy();
	}

	/// create wrapper style which will have currentTheme.get(id) as parent instead of fixed parent - to modify some base style properties in widget
	Style modifyStyle(string id) {
		Style style = new Style(null, null);
		style._parentId = id;
        style._align = Align.Unspecified; // inherit
		style._padding.left = SIZE_UNSPECIFIED; // inherit
		style._margins.left = SIZE_UNSPECIFIED; // inherit
		style._textColor = COLOR_UNSPECIFIED; // inherit
		style._textFlags = TEXT_FLAGS_UNSPECIFIED; // inherit
		return style;
	}

	// ================================================
	// override to avoid infinite recursion
	/// font size
	@property override string backgroundImageId() const {
        return _backgroundImageId;
	}
	/// minimal width constraint, 0 if limit is not set
	@property override uint minWidth() const {
        return _minWidth;
	}
	/// max width constraint, returns SIZE_UNSPECIFIED if limit is not set
	@property override uint maxWidth() const {
        return _maxWidth;
	}
	/// minimal height constraint, 0 if limit is not set
	@property override uint minHeight() const {
        return _minHeight;
	}
	/// max height constraint, SIZE_UNSPECIFIED if limit is not set
	@property override uint maxHeight() const {
        return _maxHeight;
	}

    private DrawableRef _emptyDrawable;
    @property override ref DrawableRef customDrawable(string id) const {
        if (id in _customDrawables)
            return _customDrawables[id].drawable;
        return (cast(Theme)this)._emptyDrawable;
    }

    @property override string customDrawableId(string id) const {
        if (id in _customDrawables)
            return _customDrawables[id].drawableId;
        return null;
    }

	/// create new named style or get existing
	override Style createSubstyle(string id) {
		if (id !is null && id in _byId)
			return _byId[id]; // already exists
		Style style = new Style(this, id);
		if (id !is null)
			_byId[id] = style;
        style._parentStyle = this; // as initial value, use theme as parent
		return style;
	}

	/// find style by id, returns theme if not style with specified ID is not found
	@property Style get(string id) {
		if (id !is null && id in _byId)
			return _byId[id];
		return this;
	}
	
	/// find substyle based on widget state (e.g. focused, pressed, ...)
	override const(Style) forState(uint state) const {
		return this;
	}

	void dumpStats() {
		Log.d("Theme ", _id, ": children:", _children.length, ", substates:", _substates.length, ", mapsize:", _byId.length);
	}
}

/// to access current theme
private __gshared Theme _currentTheme;
/// current theme accessor
@property Theme currentTheme() { return _currentTheme; }
/// set new current theme
@property void currentTheme(Theme theme) { 
	if (_currentTheme !is null) {
		destroy(_currentTheme);
	}
	_currentTheme = theme; 
}

immutable ATTR_SCROLLBAR_BUTTON_UP = "scrollbar_button_up";
immutable ATTR_SCROLLBAR_BUTTON_DOWN = "scrollbar_button_down";
immutable ATTR_SCROLLBAR_BUTTON_LEFT = "scrollbar_button_left";
immutable ATTR_SCROLLBAR_BUTTON_RIGHT = "scrollbar_button_right";
immutable ATTR_SCROLLBAR_INDICATOR_VERTICAL = "scrollbar_indicator_vertical";
immutable ATTR_SCROLLBAR_INDICATOR_HORIZONTAL = "scrollbar_indicator_horizontal";

Theme createDefaultTheme() {
	Log.d("Creating default theme");
	Theme res = new Theme("default");
    //res.fontSize(14);
    version (Windows) {
        res.fontFace = "Verdana";
    }
    //res.fontFace = "Arial Narrow";
    res.fontSize = 15; // TODO: choose based on DPI
	Style button = res.createSubstyle("BUTTON").backgroundImageId("btn_default_small").alignment(Align.Center).setMargins(5,5,5,5);
    res.createSubstyle("BUTTON_TRANSPARENT").backgroundImageId("btn_default_small_transparent").alignment(Align.Center);
    res.createSubstyle("BUTTON_LABEL").layoutWidth(FILL_PARENT).alignment(Align.Left|Align.VCenter);
    res.createSubstyle("BUTTON_ICON").alignment(Align.Center);
    res.createSubstyle("TEXT").setMargins(2,2,2,2).setPadding(1,1,1,1);
    res.createSubstyle("HSPACER").layoutWidth(FILL_PARENT).minWidth(5).layoutWeight(100);
    res.createSubstyle("VSPACER").layoutHeight(FILL_PARENT).minHeight(5).layoutWeight(100);
	res.createSubstyle("BUTTON_NOMARGINS").backgroundImageId("btn_default_small").alignment(Align.Center); // .setMargins(5,5,5,5)
	//button.createState(State.Enabled | State.Focused, State.Focused).backgroundImageId("btn_default_small_normal_disable_focused");
    //button.createState(State.Enabled, 0).backgroundImageId("btn_default_small_normal_disable");
    //button.createState(State.Pressed, State.Pressed).backgroundImageId("btn_default_small_pressed");
    //button.createState(State.Focused, State.Focused).backgroundImageId("btn_default_small_selected");
    //button.createState(State.Hovered, State.Hovered).backgroundImageId("btn_default_small_normal_hover");
    res.setCustomDrawable(ATTR_SCROLLBAR_BUTTON_UP, "scrollbar_btn_up");
    res.setCustomDrawable(ATTR_SCROLLBAR_BUTTON_DOWN, "scrollbar_btn_down");
    res.setCustomDrawable(ATTR_SCROLLBAR_BUTTON_LEFT, "scrollbar_btn_left");
    res.setCustomDrawable(ATTR_SCROLLBAR_BUTTON_RIGHT, "scrollbar_btn_right");
    res.setCustomDrawable(ATTR_SCROLLBAR_INDICATOR_VERTICAL, "scrollbar_indicator_vertical");
    res.setCustomDrawable(ATTR_SCROLLBAR_INDICATOR_HORIZONTAL, "scrollbar_indicator_horizontal");

    Style scrollbar = res.createSubstyle("SCROLLBAR");
    scrollbar.backgroundColor(0xC0808080);
    Style scrollbarButton = button.createSubstyle("SCROLLBAR_BUTTON");
    Style scrollbarSlider = res.createSubstyle("SLIDER");
    Style scrollbarPage = res.createSubstyle("PAGE_SCROLL").backgroundColor(0xFFFFFFFF);
    scrollbarPage.createState(State.Pressed, State.Pressed).backgroundColor(0xC0404080);
    scrollbarPage.createState(State.Hovered, State.Hovered).backgroundColor(0xF0404080);

    Style tabUp = res.createSubstyle("TAB_UP");
    tabUp.backgroundImageId("tab_up_background");
    tabUp.layoutWidth(FILL_PARENT);
    tabUp.createState(State.Selected, State.Selected).backgroundImageId("tab_up_backgrond_selected");
    Style tabUpButtonText = res.createSubstyle("TAB_UP_BUTTON_TEXT");
    tabUpButtonText.textColor(0x000000).fontSize(12).alignment(Align.Center);
    tabUpButtonText.createState(State.Selected, State.Selected).textColor(0x000000);
    tabUpButtonText.createState(State.Selected|State.Focused, State.Selected|State.Focused).textColor(0x000000);
    tabUpButtonText.createState(State.Focused, State.Focused).textColor(0x000000);
    tabUpButtonText.createState(State.Hovered, State.Hovered).textColor(0xFFE0E0);
    Style tabUpButton = res.createSubstyle("TAB_UP_BUTTON");
    tabUpButton.backgroundImageId("tab_btn_up");
    //tabUpButton.backgroundImageId("tab_btn_up_normal");
    //tabUpButton.createState(State.Selected, State.Selected).backgroundImageId("tab_btn_up_selected");
    //tabUpButton.createState(State.Selected|State.Focused, State.Selected|State.Focused).backgroundImageId("tab_btn_up_focused_selected");
    //tabUpButton.createState(State.Focused, State.Focused).backgroundImageId("tab_btn_up_focused");
    //tabUpButton.createState(State.Hovered, State.Hovered).backgroundImageId("tab_btn_up_hover");
    Style tabHost = res.createSubstyle("TAB_HOST");
    tabHost.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
    tabHost.backgroundColor(0xF0F0F0);
    Style tabWidget = res.createSubstyle("TAB_WIDGET");
	tabWidget.setPadding(3,3,3,3).backgroundColor(0xEEEEEE);
    //tabWidget.backgroundImageId("frame_blue");
	//res.dumpStats();

    Style mainMenu = res.createSubstyle("MAIN_MENU").backgroundColor(0xEFEFF2).layoutWidth(FILL_PARENT);
	Style mainMenuItem = res.createSubstyle("MAIN_MENU_ITEM").setPadding(4,2,4,2).backgroundImageId("main_menu_item_background").textFlags(TEXT_FLAGS_USE_PARENT);
    Style menuItem = res.createSubstyle("MENU_ITEM").setPadding(4,2,4,2); //.backgroundColor(0xE0E080)   ;
    menuItem.createState(State.Focused, State.Focused).backgroundColor(0x40C0C000);
    menuItem.createState(State.Pressed, State.Pressed).backgroundColor(0x4080C000);
    menuItem.createState(State.Selected, State.Selected).backgroundColor(0x00F8F9Fa);
    menuItem.createState(State.Hovered, State.Hovered).backgroundColor(0xC0FFFF00);
	res.createSubstyle("MENU_ICON").setMargins(2,2,2,2).alignment(Align.VCenter|Align.Left).createState(State.Enabled,0).alpha(0xA0);
	res.createSubstyle("MENU_LABEL").setMargins(4,2,4,2).alignment(Align.VCenter|Align.Left).textFlags(TextFlag.UnderlineHotKeys).createState(State.Enabled,0).textColor(0x80404040);
	res.createSubstyle("MAIN_MENU_LABEL").setMargins(4,2,4,2).alignment(Align.VCenter|Align.Left).textFlags(TEXT_FLAGS_USE_PARENT).createState(State.Enabled,0).textColor(0x80404040);
	res.createSubstyle("MENU_ACCEL").setMargins(4,2,4,2).alignment(Align.VCenter|Align.Left).createState(State.Enabled,0).textColor(0x80404040);

    Style transparentButtonBackground = res.createSubstyle("TRANSPARENT_BUTTON_BACKGROUND").backgroundImageId("transparent_button_background").setPadding(4,2,4,2); //.backgroundColor(0xE0E080)   ;
    //transparentButtonBackground.createState(State.Focused, State.Focused).backgroundColor(0xC0C0C000);
    //transparentButtonBackground.createState(State.Pressed, State.Pressed).backgroundColor(0x4080C000);
    //transparentButtonBackground.createState(State.Selected, State.Selected).backgroundColor(0x00F8F9Fa);
    //transparentButtonBackground.createState(State.Hovered, State.Hovered).backgroundColor(0xD0FFFF00);

    Style poopupMenu = res.createSubstyle("POPUP_MENU").backgroundImageId("popup_menu_background_normal");

    Style listItem = res.createSubstyle("LIST_ITEM").backgroundImageId("list_item_background");
    //listItem.createState(State.Selected, State.Selected).backgroundColor(0xC04040FF).textColor(0x000000);
    //listItem.createState(State.Enabled, 0).textColor(0x80000000); // half transparent text for disabled item

    Style editLine = res.createSubstyle("EDIT_LINE").backgroundImageId("editbox_background")
        .setPadding(5,6,5,6).setMargins(2,2,2,2).minWidth(40)
        .fontFace("Arial").fontFamily(FontFamily.SansSerif).fontSize(16);
    Style editBox = res.createSubstyle("EDIT_BOX").backgroundImageId("editbox_background")
        .setPadding(5,6,5,6).setMargins(2,2,2,2).minWidth(100).minHeight(60).layoutHeight(FILL_PARENT).layoutWidth(FILL_PARENT)
        .fontFace("Courier New").fontFamily(FontFamily.MonoSpace).fontSize(16);

	return res;
}

/// decode comma delimited dimension list or single value - and put to Rect
Rect decodeRect(string s) {
	uint[6] values;
	int valueCount = 0;
	int start = 0;
	for (int i = 0; i <= s.length; i++) {
		if (i == s.length || s[i] == ',') {
			if (i > start) {
				string item = s[start .. i];
				values[valueCount++] = decodeDimension(item);
				if (valueCount >= 6)
					break;
			}
			start = i + 1;
		}
	}
	if (valueCount == 1) // same value for all dimensions
		return Rect(values[0], values[0], values[0], values[0]);
	else if (valueCount == 2) // one value of horizontal, and one for vertical
		return Rect(values[0], values[1], values[0], values[1]);
	else if (valueCount == 4) // separate left, top, right, bottom
		return Rect(values[0], values[1], values[2], values[3]);
	Log.e("Invalid rect attribute value ", s);
	return Rect(0,0,0,0);
}

/// parses string like "Left|VCenter" to bit set of Align flags
ubyte decodeAlignment(string s) {
	ubyte res = 0;
	int start = 0;
	for (int i = 0; i <= s.length; i++) {
		if (i == s.length || s[i] == '|') {
			if (i > start) {
				string item = s[start .. i];
				if (item.equal("Left"))
					res |= Align.Left;
				else if (item.equal("Right"))
					res |= Align.Right;
				else if (item.equal("Top"))
					res |= Align.Top;
				else if (item.equal("Bottom"))
					res |= Align.Bottom;
				else if (item.equal("HCenter"))
					res |= Align.HCenter;
				else if (item.equal("VCenter"))
					res |= Align.VCenter;
				else if (item.equal("Center"))
					res |= Align.Center;
				else if (item.equal("TopLeft"))
					res |= Align.TopLeft;
				else
					Log.e("unknown Align value: ", item);
			}
			start = i + 1;
		}
	}
	return res;
}

/// parses string like "HotKeys|UnderlineHotKeysWhenAltPressed" to bit set of TextFlag flags
uint decodeTextFlags(string s) {
	uint res = 0;
	int start = 0;
	for (int i = 0; i <= s.length; i++) {
		if (i == s.length || s[i] == '|') {
			if (i > start) {
				string item = s[start .. i];
				if (item.equal("HotKeys"))
					res |= TextFlag.HotKeys;
				else if (item.equal("UnderlineHotKeys"))
					res |= TextFlag.UnderlineHotKeys;
				else if (item.equal("UnderlineHotKeysWhenAltPressed"))
					res |= TextFlag.UnderlineHotKeysWhenAltPressed;
				else if (item.equal("Underline"))
					res |= TextFlag.Underline;
				else if (item.equal("Unspecified"))
					res = TEXT_FLAGS_UNSPECIFIED;
				else if (item.equal("Parent"))
					res = TEXT_FLAGS_USE_PARENT;
				else
					Log.e("unknown text flag value: ", item);
			}
			start = i + 1;
		}
	}
	return res;
}

/// decode FontFamily item name to value
FontFamily decodeFontFamily(string s) {
	if (s.equal("SansSerif"))
		return FontFamily.SansSerif;
	if (s.equal("Serif"))
		return FontFamily.Serif;
	if (s.equal("Cursive"))
		return FontFamily.Cursive;
	if (s.equal("Fantasy"))
		return FontFamily.Fantasy;
	if (s.equal("MonoSpace"))
		return FontFamily.MonoSpace;
	if (s.equal("Unspecified"))
		return FontFamily.Unspecified;
	Log.e("unknown font family ", s);
	return FontFamily.SansSerif;
}

/// decode layout dimension (FILL_PARENT, WRAP_CONTENT, or just size)
int decodeLayoutDimension(string s) {
	if (s.equal("FILL_PARENT"))
		return FILL_PARENT;
	if (s.equal("WRAP_CONTENT"))
		return WRAP_CONTENT;
	return decodeDimension(s);
}

/// load style attributes from XML element
bool loadStyleAttributes(Style style, Element elem, bool allowStates) {
	if ("backgroundImageId" in elem.tag.attr)
		style.backgroundImageId = elem.tag.attr["backgroundImageId"];
	if ("backgroundColor" in elem.tag.attr)
		style.backgroundColor = decodeHexColor(elem.tag.attr["backgroundColor"]);
	if ("textColor" in elem.tag.attr)
		style.textColor = decodeHexColor(elem.tag.attr["textColor"]);
	if ("margins" in elem.tag.attr)
		style.margins = decodeRect(elem.tag.attr["margins"]);
	if ("padding" in elem.tag.attr)
		style.padding = decodeRect(elem.tag.attr["padding"]);
	if ("align" in elem.tag.attr)
		style.alignment = decodeAlignment(elem.tag.attr["align"]);
	if ("minWidth" in elem.tag.attr)
		style.minWidth = decodeDimension(elem.tag.attr["minWidth"]);
	if ("maxWidth" in elem.tag.attr)
		style.maxWidth = decodeDimension(elem.tag.attr["maxWidth"]);
	if ("minHeight" in elem.tag.attr)
		style.minHeight = decodeDimension(elem.tag.attr["minHeight"]);
	if ("maxHeight" in elem.tag.attr)
		style.maxHeight = decodeDimension(elem.tag.attr["maxHeight"]);
	if ("fontFace" in elem.tag.attr)
		style.fontFace = elem.tag.attr["fontFace"];
	if ("fontFamily" in elem.tag.attr)
		style.fontFamily = decodeFontFamily(elem.tag.attr["fontFamily"]);
	if ("fontSize" in elem.tag.attr)
		style.fontSize = cast(ushort)decodeDimension(elem.tag.attr["fontSize"]);
	if ("layoutWidth" in elem.tag.attr)
		style.layoutWidth = decodeLayoutDimension(elem.tag.attr["layoutWidth"]);
	if ("layoutHeight" in elem.tag.attr)
		style.layoutHeight = decodeLayoutDimension(elem.tag.attr["layoutHeight"]);
	if ("alpha" in elem.tag.attr)
		style.alpha = decodeDimension(elem.tag.attr["alpha"]);
	if ("textFlags" in elem.tag.attr)
		style.textFlags = decodeTextFlags(elem.tag.attr["textFlags"]);
	foreach(item; elem.elements) {
		if (allowStates && item.tag.name.equal("state")) {
			uint stateMask = 0;
			uint stateValue = 0;
			extractStateFlags(item.tag.attr, stateMask, stateValue);
			if (stateMask) {
				Style state = style.createState(stateMask, stateValue);
				loadStyleAttributes(state, item, false);
			}
		} else if (item.tag.name.equal("drawable")) {
			// <drawable id="scrollbar_button_up" value="scrollbar_btn_up"/>
			string drawableid = attrValue(item, "id");
			string drawablevalue = attrValue(item, "value");
			if (drawableid)
				style.setCustomDrawable(drawableid, drawablevalue);
		}
	}
	return true;
}

/** 
 * load theme from XML document
 * 
 * Sample:
 * ---
 * <?xml version="1.0" encoding="utf-8"?>
 * <theme id="theme_custom" parent="theme_default">
 *   	<style id="BUTTON" 
 * 			backgroundImageId="btn_default_small"
 * 	 	>
 *   	</style>
 * </theme>
 * ---
 * 
 */
bool loadTheme(Theme theme, Element doc, int level = 0) {
	if (!doc.tag.name.equal("theme")) {
		Log.e("<theme> element should be main in theme file!");
		return false;
	}
	// <theme>
	string id = attrValue(doc, "id");
	string parent = attrValue(doc, "parent");
	theme.id = id;
	if (parent.length > 0) {
		// load base theme
		if (level < 3) // to prevent infinite recursion
			loadTheme(theme, parent, level + 1);
	}
	loadStyleAttributes(theme, doc, false);
	foreach(styleitem; doc.elements) {
		if (styleitem.tag.name.equal("style")) {
			// load <style>
			string styleid = attrValue(styleitem, "id");
			string styleparent = attrValue(styleitem, "parent");
			if (styleid.length) {
				// create new style
				Style parentStyle = null;
				parentStyle = theme.get(styleparent);
				Style style = parentStyle.createSubstyle(styleid);
				loadStyleAttributes(style, styleitem, true);
			} else {
				Log.e("style without ID in theme file");
			}
		}
	}
	return true;
}

/// load theme from file
bool loadTheme(Theme theme, string resourceId, int level = 0) {

	import std.file;
	import std.string;

	string filename;
	try {
		filename = drawableCache.findResource(resourceId);
		if (!filename || !filename.endsWith(".xml"))
			return false;
		string s = cast(string)std.file.read(filename);
		
		// Check for well-formedness
		//check(s);
		
		// Make a DOM tree
		auto doc = new Document(s);
		
		return loadTheme(theme, doc);
	} catch (CheckException e) {
		Log.e("Invalid XML resource ", resourceId);
		return false;
	} catch (Throwable e) {
		Log.e("Cannot read XML resource ", resourceId, " from file ", filename, " exception: ", e);
		return false;
	}
}

/// load theme from XML file (null if failed)
Theme loadTheme(string resourceId) {
	Theme res = new Theme(resourceId);
	if (loadTheme(res, resourceId)) {
		res.id = resourceId;
		return res;
	}
	destroy(res);
	return null;
}

shared static ~this() {
	currentTheme = null;
}
