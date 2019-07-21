port module Bluetooth exposing
    ( BtDevAddress
    , BtSocketId
    , BtAdapterState
    , BtDevice
    , btAdapterStateChanged
    , btGetDevices
    , btGotDevices
    , btConnect
    , btConnected
    , btConnectionFailure
    , btDisconnect
    , btDisconnectFailure
    , btDisconnectSuccess
    , btSend
    , btSendFailure
    , btSendSuccess
    , btRecieved
    , btReceiveError
    )

type alias BtDevAddress = String
type alias BtSocketId = Int

type alias BtAdapterState =
    { address     : String
    , name        : String
    , powered      : Bool
    , available   : Bool
    , discovering : Bool
    }

type alias BtDevice = --partical
    { address     : String
    , name        : Maybe String
    , deviceClass : Maybe Int
    , venderId    : Maybe Int
    , productId   : Maybe Int
    , deviceId    : Maybe Int
    , paired      : Maybe Bool
    , connected   : Maybe Bool
    , uuids       : List String
    }

port btAdapterStateChanged : (BtAdapterState -> msg) -> Sub msg
port btRecieved : ( (Int, List Int) -> msg) -> Sub msg
port btReceiveError : (String -> msg) -> Sub msg
port btGetDevices : () -> Cmd msg
port btGotDevices : (List BtDevice -> msg) -> Sub msg
port btConnect : (BtDevAddress) -> Cmd msg
port btConnected : (BtSocketId -> msg) -> Sub msg
port btConnectionFailure : (String -> msg) -> Sub msg
port btDisconnect : (BtSocketId) -> Cmd msg
port btDisconnectFailure : (String -> msg) -> Sub msg
port btDisconnectSuccess : (BtSocketId -> msg) -> Sub msg
port btSend : (BtSocketId, List Int) -> Cmd msg
port btSendFailure :  (String -> msg) -> Sub msg
port btSendSuccess :  (Int -> msg) -> Sub msg
