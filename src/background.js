/**
 * Listens for the app launching, then creates the window.
 *
 * @see http://developer.chrome.com/apps/app.runtime.html
 * @see http://developer.chrome.com/apps/app.window.html
 */
chrome.app.runtime.onLaunched.addListener(function(launchData)
{
  chrome.app.window.create(
    'index.html',
    {
      id: 'main',
      bounds:
      {
        width: 800, height: 500
      },
      minWidth: 640,
      minHeight: 480,
      "resizable": true
    }
  );
});
