function ifUndef(defaultValue, value) {
    if (value === undefined) {
        return defaultValue;
    }
    return value;
}

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

    app.ports.getBtDevices.subscribe( function (msg) {
        chrome.bluetooth.getDevices(function(devices) {
            ds = devices.map( function (d) {
                return  { address     : d.address,
                          name        : ifUndef(null, d.name),
                          deviceClass : ifUndef(null, d.deviceClass),
                          venderId    : ifUndef(null, d.venderId),
                          productId   : ifUndef(null, d.productId),
                          deviceId    : ifUndef(null, d.deviceId),
                          paired      : ifUndef(null, d.paired),
                          connected   : ifUndef(null, d.connected),
                          uuids       : ifUndef([]  , d.uuids)
                        };
            });
            app.ports.gotBtDevices.send(ds);
        });
    });

});
