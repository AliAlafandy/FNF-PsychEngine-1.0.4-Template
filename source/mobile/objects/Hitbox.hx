package mobile.objects;

import openfl.display.BitmapData;
import openfl.display.Shape;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import openfl.geom.Matrix;

class Hitbox extends MobileInputManager implements IMobileControls
{
	final offsetFir:Int = (ClientPrefs.data.hitboxPos ? Std.int(FlxG.height / 4) * 3 : 0);
	final offsetSec:Int = (ClientPrefs.data.hitboxPos ? 0 : Std.int(FlxG.height / 4));

	public var buttonLeft:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_LEFT, MobileInputID.NOTE_LEFT]);
	public var buttonDown:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_DOWN, MobileInputID.NOTE_DOWN]);
	public var buttonUp:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_UP, MobileInputID.NOTE_UP]);
	public var buttonRight:TouchButton = new TouchButton(0, 0, [MobileInputID.HITBOX_RIGHT, MobileInputID.NOTE_RIGHT]);
	public var buttonExtra:TouchButton = new TouchButton(0, 0, [MobileInputID.EXTRA_1]);
	public var buttonExtra2:TouchButton = new TouchButton(0, 0, [MobileInputID.EXTRA_2]);

	public var instance:MobileInputManager;
	public var onButtonDown:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();
	public var onButtonUp:FlxTypedSignal<TouchButton->Void> = new FlxTypedSignal<TouchButton->Void>();

	var storedButtonsIDs:Map<String, Array<MobileInputID>> = new Map<String, Array<MobileInputID>>();
	var hintTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	var hintLaneTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	var hintScaleTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	var hintFlashTweens:Map<String, FlxTween> = new Map<String, FlxTween>();

	public function new(?extraMode:ExtraActions = NONE)
	{
		super();

		for (button in Reflect.fields(this))
		{
			var field = Reflect.field(this, button);
			if (Std.isOfType(field, TouchButton))
				storedButtonsIDs.set(button, Reflect.getProperty(field, 'IDs'));
		}

		switch (extraMode)
		{
			case NONE:
				add(buttonLeft = createHint(0, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFFC24B99));
				add(buttonDown = createHint(FlxG.width / 4, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFF00FFFF));
				add(buttonUp = createHint(FlxG.width / 2, 0, Std.int(FlxG.width / 4), FlxG.height, 0xFF12FA05));
				add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), 0, Std.int(FlxG.width / 4), FlxG.height, 0xFFF9393F));
			case SINGLE:
				add(buttonLeft = createHint(0, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFFC24B99));
				add(buttonDown = createHint(FlxG.width / 4, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF00FFFF));
				add(buttonUp = createHint(FlxG.width / 2, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF12FA05));
				add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3,
					0xFFF9393F));
				add(buttonExtra = createHint(0, offsetFir, FlxG.width, Std.int(FlxG.height / 4), 0xFF0066FF));
			case DOUBLE:
				add(buttonLeft = createHint(0, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFFC24B99));
				add(buttonDown = createHint(FlxG.width / 4, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF00FFFF));
				add(buttonUp = createHint(FlxG.width / 2, offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3, 0xFF12FA05));
				add(buttonRight = createHint((FlxG.width / 2) + (FlxG.width / 4), offsetSec, Std.int(FlxG.width / 4), Std.int(FlxG.height / 4) * 3,
					0xFFF9393F));
				add(buttonExtra2 = createHint(Std.int(FlxG.width / 2), offsetFir, Std.int(FlxG.width / 2), Std.int(FlxG.height / 4), 0xA6FF00));
				add(buttonExtra = createHint(0, offsetFir, Std.int(FlxG.width / 2), Std.int(FlxG.height / 4), 0xFF0066FF));
		}

		for (button in Reflect.fields(this))
		{
			if (Std.isOfType(Reflect.field(this, button), TouchButton))
				Reflect.setProperty(Reflect.getProperty(this, button), 'IDs', storedButtonsIDs.get(button));
		}

		storedButtonsIDs.clear();
		scrollFactor.set();
		updateTrackedButtons();

		instance = this;
	}

	override function destroy()
	{
		super.destroy();
		onButtonUp.destroy();
		onButtonDown.destroy();

		for (fieldName in Reflect.fields(this))
		{
			var field = Reflect.field(this, fieldName);
			if (Std.isOfType(field, TouchButton))
				Reflect.setField(this, fieldName, FlxDestroyUtil.destroy(field));
		}

		hintTweens.clear();
		hintLaneTweens.clear();
		hintScaleTweens.clear();
		hintFlashTweens.clear();
	}

	private function createHint(X:Float, Y:Float, Width:Int, Height:Int, Color:Int = 0xFFFFFF):TouchButton
	{
		var hint = new TouchButton(X, Y);
		var hintKey = X + '_' + Y;

		hint.statusAlphas = [];
		hint.statusIndicatorType = NONE;
		hint.loadGraphic(createHintGraphic(Width, Height, Color));

		hint.label = new FlxSprite();
		hint.labelStatusDiff = (ClientPrefs.data.hitboxType != "Hidden") ? ClientPrefs.data.controlsAlpha : 0.00001;
		hint.label.loadGraphic(createHintGraphic(Width, Math.floor(Height * 0.035), Color, true));
		if (ClientPrefs.data.hitboxPos)
			hint.label.offset.y -= (hint.height - hint.label.height) / 2;
		else
			hint.label.offset.y += (hint.height - hint.label.height) / 2;

		if (ClientPrefs.data.hitboxType != "Hidden")
		{
			hint.onDown.callback = function()
			{
				onButtonDown.dispatch(hint);
				spawnRipple(hint, Color);
				animatePress(hint, hintKey, Color, true);
			}

			hint.onOut.callback = hint.onUp.callback = function()
			{
				onButtonUp.dispatch(hint);
				animatePress(hint, hintKey, Color, false);
			}
		}
		else
		{
			hint.onDown.callback = () -> onButtonDown.dispatch(hint);
			hint.onOut.callback = hint.onUp.callback = () -> onButtonUp.dispatch(hint);
		}

		hint.immovable = hint.multiTouch = true;
		hint.solid = hint.moves = false;
		hint.alpha = 0.00001;
		hint.label.alpha = (ClientPrefs.data.hitboxType != "Hidden") ? ClientPrefs.data.controlsAlpha : 0.00001;
		hint.canChangeLabelAlpha = false;
		hint.label.antialiasing = hint.antialiasing = ClientPrefs.data.antialiasing;
		hint.color = Color;
		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end
		return hint;
	}

	function animatePress(hint:TouchButton, key:String, color:Int, pressed:Bool):Void
	{
		cancelTween(hintTweens, key);
		cancelTween(hintLaneTweens, key);
		cancelTween(hintScaleTweens, key);
		cancelTween(hintFlashTweens, key);

		var targetAlpha = pressed ? ClientPrefs.data.controlsAlpha : 0.00001;
		var labelAlpha = pressed ? 0.00001 : ClientPrefs.data.controlsAlpha;
		var targetScale = pressed ? 1.06 : 1.0;
		var duration = ClientPrefs.data.controlsAlpha / (pressed ? 100 : 10);

		hintTweens.set(key, FlxTween.tween(hint, {alpha: targetAlpha}, duration, {
			ease: FlxEase.circInOut,
			onComplete: (twn:FlxTween) -> hintTweens.remove(key)
		}));

		hintLaneTweens.set(key, FlxTween.tween(hint.label, {alpha: labelAlpha}, duration, {
			ease: FlxEase.circInOut,
			onComplete: (twn:FlxTween) -> hintLaneTweens.remove(key)
		}));

		hintScaleTweens.set(key, FlxTween.tween(hint.scale, {x: targetScale, y: targetScale}, 0.12, {
			ease: pressed ? FlxEase.backOut : FlxEase.quadOut,
			onComplete: (twn:FlxTween) -> hintScaleTweens.remove(key)
		}));

		hint.color = pressed ? FlxColor.WHITE : color;
		if (pressed)
		{
			hintFlashTweens.set(key, FlxTween.color(hint, 0.2, FlxColor.WHITE, color, {
				onComplete: (twn:FlxTween) -> hintFlashTweens.remove(key)
			}));
		}
	}

	function cancelTween(map:Map<String, FlxTween>, key:String):Void
	{
		var tween = map.get(key);
		if (tween != null)
			tween.cancel();
	}

	function spawnRipple(hint:TouchButton, color:Int):Void
	{
		var size:Int = Std.int(hint.width * 0.4);
		var ripple = new FlxSprite();
		ripple.loadGraphic(createRippleGraphic(size, color));
		ripple.x = hint.x + hint.width / 2 - ripple.width / 2;
		ripple.y = hint.y + hint.height / 2 - ripple.height / 2;
		ripple.alpha = 0.5;
		ripple.scale.set(0.3, 0.3);
		ripple.scrollFactor.set();
		ripple.cameras = hint.cameras;

		FlxG.state.add(ripple);

		FlxTween.tween(ripple.scale, {x: 1.6, y: 1.6}, 0.4, {ease: FlxEase.quadOut});
		FlxTween.tween(ripple, {alpha: 0}, 0.4, {
			ease: FlxEase.quadOut,
			onComplete: (twn:FlxTween) -> {
				FlxG.state.remove(ripple, true);
				ripple.destroy();
			}
		});
	}

	function createRippleGraphic(size:Int, color:Int):FlxGraphic
	{
		var shape:Shape = new Shape();
		shape.graphics.lineStyle(4, color, 1);
		shape.graphics.drawCircle(size / 2, size / 2, size / 2 - 2);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(size, size, true, 0);
		bitmap.draw(shape);

		return FlxG.bitmap.add(bitmap);
	}

	function createHintGraphic(Width:Int, Height:Int, Color:Int = 0xFFFFFF, ?isLane:Bool = false):FlxGraphic
	{
		var shape:Shape = new Shape();
		var corner:Float = isLane ? 0 : Math.min(Width, Height) * 0.18;

		if (ClientPrefs.data.hitboxType == "No Gradient")
		{
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(Width, Height, 0, 0, 0);

			if (isLane)
				shape.graphics.beginFill(0xFFFFFF);
			else
				shape.graphics.beginGradientFill(RADIAL, [0xFFFFFF, 0xFFFFFF], [0, 1], [60, 255], matrix, PAD, RGB, 0);
			shape.graphics.drawRoundRect(0, 0, Width, Height, corner, corner);
			shape.graphics.endFill();
		}
		else if (ClientPrefs.data.hitboxType == "No Gradient (Old)")
		{
			shape.graphics.lineStyle(10, 0xFFFFFF, 1);
			shape.graphics.drawRoundRect(0, 0, Width, Height, corner, corner);
			shape.graphics.endFill();
		}
		else
		{
			shape.graphics.lineStyle(3, 0xFFFFFF, 1);
			shape.graphics.drawRoundRect(0, 0, Width, Height, corner, corner);
			shape.graphics.lineStyle(0, 0, 0);
			shape.graphics.drawRoundRect(3, 3, Width - 6, Height - 6, corner * 0.85, corner * 0.85);
			shape.graphics.endFill();
			if (isLane)
				shape.graphics.beginFill(0xFFFFFF);
			else
				shape.graphics.beginGradientFill(RADIAL, [0xFFFFFF, FlxColor.TRANSPARENT], [1, 0], [0, 255], null, null, null, 0.5);
			shape.graphics.drawRoundRect(3, 3, Width - 6, Height - 6, corner * 0.85, corner * 0.85);
			shape.graphics.endFill();
		}

		var bitmap:BitmapData = new BitmapData(Width, Height, true, 0);
		bitmap.draw(shape);

		return FlxG.bitmap.add(bitmap);
	}
}
