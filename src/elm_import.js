document.addEventListener('DOMContentLoaded', function() {
    var app = Elm.Main.init({
        node: document.getElementById('elm'),
        flags:0
    });

    chrome.bluetooth.onAdapterStateChanged.addListener(
        function (adapter) {
            app.ports.adapterStateChanged.send(adapter)
        }
    );
});
