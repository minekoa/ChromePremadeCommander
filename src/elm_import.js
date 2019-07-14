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
            const ds = devices.map( function (d) {
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

    app.ports.btConnect.subscribe( function (devAddress) {
        chrome.bluetoothSocket.create( function(createInfo) {

            if (chrome.runtime.lastError) {
                app.ports.btConnectionFailure.send( chrome.runtime.lastError.message );
                return;
            }

            chrome.bluetoothSocket.connect(
                createInfo.socketId,
                devAddress,"1101",
                function () {
                    if (chrome.runtime.lastError) {
                        app.ports.btConnectionFailure.send( chrome.runtime.lastError.message );
                        return;
                    }

                    app.ports.btConnected.send(createInfo.socketId);
                }
            );
        });
    });

    app.ports.btSend.subscribe( function ([socketId, charlist]) {
        var buf     = new ArrayBuffer(charlist.length);
        var bufView = new Uint8Array(buf);
        for (var i=0; i< charlist.length; i++) {
            bufView[i] = charlist[i];
        }

        chrome.bluetoothSocket.send(
            socketId, buf,
            function(bytes_sent) {
                if (chrome.runtime.lastError) {
                    app.ports.btSendFailure.send(chrome.runtime.lastError.message)
                }
                else {
                    app.ports.btSendSuccess.send(bytes_sent)
                }
            }
        );
    });
});
