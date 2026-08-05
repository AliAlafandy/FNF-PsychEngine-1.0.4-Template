package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal;

enum InputState {
	PRESSED;
	JUST_PRESSED;
	JUST_RELEASED;
}

class Controls
{
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var mobileBinds:Map<String, Array<MobileInputID>>;

	public var controllerMode(default, null):Bool = false;
	public var onControllerModeChanged:FlxTypedSignal<Bool->Void> = new FlxTypedSignal();

	public function justPressed(key:String):Bool
	{
		return check(key, JUST_PRESSED);
	}

	public function pressed(key:String):Bool
	{
		return check(key, PRESSED);
	}

	public function justReleased(key:String):Bool
	{
		return check(key, JUST_RELEASED);
	}

	public function anyJustPressed(keys:Array<String>):Bool
	{
		for (key in keys)
			if (justPressed(key))
				return true;

		return false;
	}

	public function anyPressed(keys:Array<String>):Bool
	{
		for (key in keys)
			if (pressed(key))
				return true;

		return false;
	}

	public function anyJustReleased(keys:Array<String>):Bool
	{
		for (key in keys)
			if (justReleased(key))
				return true;

		return false;
	}

	private function check(key:String, state:InputState):Bool
	{
		var result:Bool = checkKeyboard(keyboardBinds.get(key), state);
		if (result)
			setControllerMode(false);

		return result
			|| checkGamepad(gamepadBinds.get(key), state)
			|| checkMobileC(mobileBinds.get(key), state)
			|| checkTouchPad(mobileBinds.get(key), state);
	}

	private function checkKeyboard(keys:Array<FlxKey>, state:InputState):Bool
	{
		if (keys == null)
			return false;

		return switch (state)
		{
			case PRESSED: FlxG.keys.anyPressed(keys);
			case JUST_PRESSED: FlxG.keys.anyJustPressed(keys);
			case JUST_RELEASED: FlxG.keys.anyJustReleased(keys);
		}
	}

	private function checkGamepad(keys:Array<FlxGamepadInputID>, state:InputState):Bool
	{
		if (keys == null)
			return false;

		for (key in keys)
		{
			var active:Bool = switch (state)
			{
				case PRESSED: FlxG.gamepads.anyPressed(key);
				case JUST_PRESSED: FlxG.gamepads.anyJustPressed(key);
				case JUST_RELEASED: FlxG.gamepads.anyJustReleased(key);
			}

			if (active)
			{
				setControllerMode(true);
				return true;
			}
		}

		return false;
	}

	private function checkMobileC(keys:Array<MobileInputID>, state:InputState):Bool
	{
		if (keys == null || requestedMobileC == null || requestedMobileC.instance == null)
			return false;

		return switch (state)
		{
			case PRESSED: requestedMobileC.instance.anyPressed(keys);
			case JUST_PRESSED: requestedMobileC.instance.anyJustPressed(keys);
			case JUST_RELEASED: requestedMobileC.instance.anyJustReleased(keys);
		}
	}

	private function checkTouchPad(keys:Array<MobileInputID>, state:InputState):Bool
	{
		var touchPad:Dynamic = requestedInstance != null ? requestedInstance.touchPad : null;
		if (keys == null || touchPad == null)
			return false;

		return switch (state)
		{
			case PRESSED: touchPad.anyPressed(keys);
			case JUST_PRESSED: touchPad.anyJustPressed(keys);
			case JUST_RELEASED: touchPad.anyJustReleased(keys);
		}
	}

	private function setControllerMode(value:Bool):Void
	{
		if (controllerMode != value)
		{
			controllerMode = value;
			onControllerModeChanged.dispatch(value);
		}
	}

	public var isInSubstate:Bool = false;
	public var requestedInstance(get, default):Dynamic;
	public var requestedMobileC(get, default):IMobileControls;
	public var mobileC(get, never):Bool;

	@:noCompletion
	private function get_requestedInstance():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance;
		else
			return MusicBeatState.getState();
	}

	@:noCompletion
	private function get_requestedMobileC():IMobileControls
	{
		return requestedInstance != null ? requestedInstance.mobileControls : null;
	}

	@:noCompletion
	private function get_mobileC():Bool
	{
		return ClientPrefs.data.controlsAlpha >= 0.1;
	}

	public static var instance:Controls;

	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
		mobileBinds = ClientPrefs.mobileBinds;
	}
}
