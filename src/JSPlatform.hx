package src;

import src.Util;

class JSPlatform {
	#if js
	public static function initFullscreenEnforcer() {
		var dislikesFullscreen = false;
		var fullscreenEnforcer = js.Browser.document.querySelector("#fullscreen-enforcer");

		fullscreenEnforcer.addEventListener('click', () -> {
			js.Browser.document.documentElement.requestFullscreen();
		});

		var enterFullscreenButton = js.Browser.document.querySelector("#enter-fullscreen");
		enterFullscreenButton.addEventListener('click', () -> {
			js.Browser.document.documentElement.requestFullscreen();
			dislikesFullscreen = false;
		});

		var fullscreenButtonVisibility = true;

		var setEnterFullscreenButtonVisibility = (state:Bool) -> {
			fullscreenButtonVisibility = state;

			if (state && Util.isTouchDevice() && !Util.isSafari() && !Util.isInFullscreen()) {
				enterFullscreenButton.classList.remove('hidden');
			} else {
				enterFullscreenButton.classList.add('hidden');
			}
		}

		var lastImmunityTime = Math.NEGATIVE_INFINITY;

		if (!Util.isIOS()) {
			js.Browser.window.setInterval(() -> {
				if (js.Browser.document.activeElement != null) {
					if (Util.isTouchDevice() && !Util.isSafari()) {
						if (Util.isInFullscreen()) {
							// They're in fullscreen, hide the overlay
							fullscreenEnforcer.classList.add('hidden');
						} else if (!dislikesFullscreen && js.Browser.window.performance.now() - lastImmunityTime > 666) {
							// They're not in fullscreen, show the overlay
							fullscreenEnforcer.classList.remove('hidden');
						}
					}

					setEnterFullscreenButtonVisibility(fullscreenButtonVisibility);
				}
			}, 250);
		}
	}
	#end
}
