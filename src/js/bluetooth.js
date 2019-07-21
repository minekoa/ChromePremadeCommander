function ifUndef(defaultValue, value) {
    if (value === undefined) {
        return defaultValue;
    }
    return value;
}

function constructBluetoothPorts(app) {

    chrome.bluetooth.onAdapterStateChanged.addListener(
        function (adapter) {
            app.ports.btAdapterStateChanged.send(adapter)
        }
    );

    chrome.bluetoothSocket.onReceive.addListener(
        function (info) {
            const numbytes = info.data.byteLength;
            const bufView  = new Uint8Array(info.data);
            let rcvdata = [];
            for (var i=0; i< info.data.byteLength; i++) {
                rcvdata.push(bufView[i]);
            }

            app.ports.btRecieved.send([numbytes, rcvdata]);
        }
    );

    chrome.bluetoothSocket.onReceiveError.addListener(
        function (errorInfo) {
            app.ports.btReceiveError.send(errorInfo.errorMessage)
        }
    );

    app.ports.btGetDevices.subscribe( function (msg) {
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
            app.ports.btGotDevices.send(ds);
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

    app.ports.btDisconnect.subscribe( function (socketId) {
        chrome.bluetoothSocket.disconnect(socketId);
        if (chrome.runtime.lastError) {
            app.ports.btDisconnectFailure.send(chrome.runtime.lastError.message)
        }
        else {
            app.ports.btDisconnectSuccess.send(socketId)
        }
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

    /* Binding chrome.bluetooth API and Elm's Ports completed above.
     * Finally, get the first adapter status.
     */
    chrome.bluetooth.getAdapterState(
        function (adapter) {
            app.ports.btAdapterStateChanged.send(adapter)
        }
    );
}
