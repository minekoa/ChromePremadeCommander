document.addEventListener('DOMContentLoaded', function() {
    var app = Elm.Main.init({
        node: document.getElementById('elm'),
        flags:0
    });
    constructBluetoothPorts(app);
});
