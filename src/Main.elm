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

type alias BtDevAddress = String
type alias BtSocketId = Int

port adapterStateChanged : (BtAdapterState -> msg) -> Sub msg
port getBtDevices : () -> Cmd msg
port gotBtDevices : (List BtDevice -> msg) -> Sub msg
port btConnect : (BtDevAddress) -> Cmd msg
port btConnected : (BtSocketId -> msg) -> Sub msg
port btConnectionFailure : (String -> msg) -> Sub msg
port btSend : (BtSocketId, List Int) -> Cmd msg
port btSendFailure :  (String -> msg) -> Sub msg
port btSendSuccess :  (Int -> msg) -> Sub msg

init : Int -> ( Model, Cmd Msg )
init _ =
    ( Model "" [] "" Nothing []
          Nothing Nothing
    , Cmd.none )


type alias Model =
    { sendMsg : String
    , response : List String
    , statusText : String
    , btAdapterState : Maybe BtAdapterState
    , btDevices : List BtDevice

    , btDevice   : Maybe BtDevice
    , btSocketId : Maybe BtSocketId
    }

type alias BluetoothControl =
    { adapterPowered : Bool
    }


type Msg
    = InputSendMsg String
    | SendMsg
    | Connect
    | Disconnect
    | ClearResponse
    | SelectDevice BtDevice
    | BtAdapterStateChanged BtAdapterState
    | GotBtDevices (List BtDevice)
    | BtConnected (BtSocketId)
    | BtConnectionFailure (String)
    | BtSendSuccess Int
    | BtSendFailure String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputSendMsg txt ->
            ( { model | sendMsg = txt }
            , Cmd.none
            )

        SendMsg ->
            ( model
            , case (model.btSocketId, hexStrToAsciiList model.sendMsg) of
                  (Just sockId, Just sndmsg) ->
                      btSend (sockId, sndmsg)
                  _ ->
                      Cmd.none
            )

        Connect ->
            ( model
            , case model.btDevice of
                  Just dev -> btConnect dev.address
                  Nothing  -> Cmd.none
            )

        Disconnect ->
            ( model
            , Cmd.none
            )

        ClearResponse ->
            ( { model | response = [] }
            , Cmd.none
            )

        SelectDevice device ->
            ( {model | btDevice = Just device}
            , Cmd.none
            )

        BtAdapterStateChanged  adapterState ->
            ( { model
                  | btAdapterState = Just adapterState
                  , btDevices = []
                  , btDevice = Nothing
                  , btSocketId = Nothing
              }
            , if adapterState.powered
              then getBtDevices ()
              else Cmd.none
            )

        GotBtDevices devices ->
            ( { model | btDevices = devices }
            , Cmd.none
            )

        BtConnected socketId ->
            ( { model | btSocketId = Just socketId }
            , Cmd.none
            )

        BtConnectionFailure errMsg ->
            ( { model
                  | btSocketId = Nothing
                  , statusText = "Connection Error : " ++ errMsg
              }
            , Cmd.none
            )

        BtSendSuccess nBytesSent ->
            ( { model
                  | btSocketId = Nothing
                  , statusText = "Sent " ++ (String.fromInt nBytesSent) ++ " bytes"
              }
            , Cmd.none
            )

        BtSendFailure errMsg ->
            ( { model
                  | btSocketId = Nothing
                  , statusText = "Send Error : " ++ errMsg
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ adapterStateChanged BtAdapterStateChanged
        , gotBtDevices GotBtDevices
        , btConnected BtConnected
        , btConnectionFailure BtConnectionFailure
        , btSendFailure BtSendFailure
        , btSendSuccess BtSendSuccess
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
                , style "background-color" <| if (hexStrToAsciiList model.sendMsg) == Nothing then "pink" else "inherit"
                ]
              []
        , button [ type_ "button"
                 , onClick SendMsg
                 , disabled <| if model.btSocketId == Nothing then True else False
                 ]
            [ text "Send" ]
        , button [ type_ "button"
                 , onClick Disconnect
                 , disabled <| if model.btSocketId == Nothing then True else False
                 ]
            [ text "Dissconnect" ]
        , button [ type_ "button"
                 , onClick Connect
                 , disabled <| if model.btDevice == Nothing then True else False
                 ]
            [ text "Connect" ]
        ]

btDevicesView : Model -> Html Msg
btDevicesView model =
    div [] <|
    List.map (\d -> div [ onClick (SelectDevice d)
                        , style "background-color" (if Just d == model.btDevice then "pink" else "inherit")
                        ]
                  [ text d.address
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

hexStrToAsciiList : String -> Maybe (List Int)
hexStrToAsciiList hexString =
    hexStrToAsciiList_ (String.toList hexString) []
        |> Maybe.andThen (List.reverse >> Just)


hexStrToAsciiList_ : List Char -> List Int -> Maybe (List Int)
hexStrToAsciiList_ hexString acc =
    case hexString of
        a :: b :: xs ->
            case (hexCharToInt a, hexCharToInt b) of
                (Just aa, Just bb) ->
                    hexStrToAsciiList_ xs ((aa * 16 + bb) :: acc)
                _ ->
                    Nothing
        [] ->
            Just acc
        _ ->
            Nothing


hexCharToInt : Char -> Maybe Int
hexCharToInt c =
    case Char.toUpper c of
        '0' -> Just 0
        '1' -> Just 1
        '2' -> Just 2
        '3' -> Just 3
        '4' -> Just 4
        '5' -> Just 5
        '6' -> Just 6
        '7' -> Just 7
        '8' -> Just 8
        '9' -> Just 9
        'A' -> Just 10
        'B' -> Just 11
        'C' -> Just 12
        'D' -> Just 13
        'E' -> Just 14
        'F' -> Just 15
        _   -> Nothing
