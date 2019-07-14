port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)

main : Program Int Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }

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

port adapterStateChanged : (BtAdapterState -> msg) -> Sub msg
port getBtDevices : () -> Cmd msg
port gotBtDevices : (List BtDevice -> msg) -> Sub msg

init : Int -> ( Model, Cmd Msg )
init _ =
    ( Model "" [] "" Nothing [], Cmd.none )


type alias Model =
    { sendMsg : String
    , response : List String
    , statusText : String
    , btAdapterState : Maybe BtAdapterState
    , btDevices : List BtDevice
    }

type alias BluetoothControl =
    { adapterPowered : Bool
    }


type Msg
    = InputSendMsg String
    | SendMsg
    | Disconnect
    | ClearResponse
    | BtAdapterStateChanged BtAdapterState
    | GotBtDevices (List BtDevice)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputSendMsg txt ->
            ( { model | sendMsg = txt }
            , Cmd.none
            )

        SendMsg ->
            ( model
            , Cmd.none
            )

        Disconnect ->
            ( model
            , Cmd.none
            )

        ClearResponse ->
            ( { model | response = [] }
            , Cmd.none
            )

        BtAdapterStateChanged  adapterState ->
            ( { model | btAdapterState = Just adapterState }
            , case adapterState.powered of
                  True -> getBtDevices ()
                  False -> Cmd.none
            )

        GotBtDevices devices ->
            ( { model | btDevices = devices }
            , Cmd.none
            )

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ adapterStateChanged BtAdapterStateChanged
        , gotBtDevices GotBtDevices
        ]


view : Model -> Html Msg
view model =
    div []
        [ sendbox model
        , statusBox model
        , case model.btAdapterState of
              Nothing ->
                  div [] [ text "Bluetooth is turned off" ]
              Just adapterState ->
                  adapterStateView adapterState
        , btDevicesView model
        ]


sendbox : Model -> Html Msg
sendbox model =
    div []
        [ input [ type_ "text"
                , value model.sendMsg
                , onInput InputSendMsg
                ]
              []
        , button [ type_ "button"
                 , onClick SendMsg
                 ]
            [ text "Send" ]
        , button [ type_ "button"
                 , onClick Disconnect
                 ]
            [ text "Dissconnect" ]
        ]

btDevicesView : Model -> Html Msg
btDevicesView model =
    div [] <|
    List.map (\d -> div [] [ text d.address
                           , text " : "
                           , d.name |> Maybe.withDefault "" |> text
                           ])
        model.btDevices


statusBox model =
    div []
        [ div [] [ text model.statusText ]
        , button [ type_ "button"
                 , onClick ClearResponse
                 ]
              [text "Clear"]
        ]

adapterStateView : BtAdapterState -> Html Msg
adapterStateView adapterState =
    let
        b2s = \b -> case b of
                        True -> "true"
                        False -> "false"
    in
        div []
            [ div [] [ text "address    : " , text adapterState.address ]
            , div [] [ text "name       : " , text adapterState.name ]
            , div [] [ text "powered    : " , text <| b2s adapterState.powered ]
            , div [] [ text "available  : " , text <| b2s adapterState.available ]
            , div [] [ text "discovering: " , text <| b2s adapterState.discovering ]
            ]
