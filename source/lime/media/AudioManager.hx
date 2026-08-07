package lime.media;

import haxe.Timer;
import lime._internal.backend.native.NativeCFFI;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
import backend.ALSoftConfig;
#if (js && html5)
import js.Browser;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class AudioManager
{
	public static var context:AudioContext;

	private static var cleanupTimer:Timer;

	public static function init(context:AudioContext = null):Void
	{
		if (AudioManager.context != null)
			return;

		if (context == null)
		{
			context = new AudioContext();
			setupOpenAL(context);
		}

		AudioManager.context = context;
		startCleanupTimer();
	}

	private static function setupOpenAL(context:AudioContext):Void
	{
		#if !lime_doc_gen
		if (context.type != OPENAL)
			return;

		var alc = context.openal;

		#if (lime_openal && !ios)
		ALSoftConfig.init();
		#end

		var device = alc.openDevice();
		var ctx = alc.createContext(device);
		alc.makeContextCurrent(ctx);
		alc.processContext(ctx);
		#end
	}

	private static function startCleanupTimer():Void
	{
		#if (lime_cffi && !macro && lime_openal && (ios || tvos || mac))
		cleanupTimer = new Timer(100);
		cleanupTimer.run = function()
		{
			NativeCFFI.lime_al_cleanup();
		};
		#end
	}

	private static function stopCleanupTimer():Void
	{
		#if (lime_cffi && !macro && lime_openal && (ios || tvos || mac))
		if (cleanupTimer != null)
		{
			cleanupTimer.stop();
			cleanupTimer = null;
		}
		#end
	}

	private static function getALC():Dynamic
	{
		#if !lime_doc_gen
		return (context != null && context.type == OPENAL) ? context.openal : null;
		#else
		return null;
		#end
	}

	public static function resume():Void
	{
		var alc = getALC();
		if (alc == null)
			return;

		var currentContext = alc.getCurrentContext();
		if (currentContext == null)
			return;

		var device = alc.getContextsDevice(currentContext);
		alc.resumeDevice(device);
		alc.processContext(currentContext);
	}

	public static function suspend():Void
	{
		var alc = getALC();
		if (alc == null)
			return;

		var currentContext = alc.getCurrentContext();
		if (currentContext == null)
			return;

		alc.suspendContext(currentContext);

		var device = alc.getContextsDevice(currentContext);
		if (device != null)
			alc.pauseDevice(device);
	}

	public static function shutdown():Void
	{
		stopCleanupTimer();

		var alc = getALC();
		if (alc != null)
		{
			var currentContext = alc.getCurrentContext();
			if (currentContext != null)
			{
				var device = alc.getContextsDevice(currentContext);
				alc.makeContextCurrent(null);
				alc.destroyContext(currentContext);

				if (device != null)
					alc.closeDevice(device);
			}
		}

		context = null;
	}
}
