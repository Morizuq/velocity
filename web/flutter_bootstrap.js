{{flutter_js}}
{{flutter_build_config}}

const loaderContainer = document.getElementById('loading-container') || document.getElementById('loading-indicator');

function dismissLoader() {
  if (loaderContainer && loaderContainer.style.opacity !== '0') {
    loaderContainer.style.opacity = '0';
    setTimeout(() => {
      if (loaderContainer && loaderContainer.parentNode) {
        loaderContainer.parentNode.removeChild(loaderContainer);
      }
    }, 400);
  }
}

// Dismiss on first visual paint event
window.addEventListener('flutter-first-frame', dismissLoader);

// Safety timeout: loader will NEVER hang for more than 4 seconds under any network circumstance
setTimeout(dismissLoader, 4000);

_flutter.loader.load({
  // Omitting serviceWorker completely prevents Flutter PWA cache interception,
  // guaranteeing React-like instantaneous updates on regular browser refresh.
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    dismissLoader();
  }
});
