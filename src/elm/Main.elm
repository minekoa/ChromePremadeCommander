module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Bitwise exposing (xor)

import Bluetooth exposing (..)

main : Program Int Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



init : Int -> ( Model, Cmd Msg )
init _ =
    ( Model "" [] "" Nothing Nothing []
          Nothing Nothing
    , Cmd.none )

type BtCommunicationDirecion = Send | Recv

type alias BtCommunicationLogItem =
    { direction : BtCommunicationDirecion
    , message   : (List Int)
    }


type alias Model =
    { sendMsg : String
    , btCommunicationLog : List BtCommunicationLogItem
    , statusText : String
    , selectedDevice   : Maybe BtDevice
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
    | ValidateSndMsg
    | SendMsg
    | Connect
    | Disconnect
    | ClearResponse
    | SelectDevice BtDevice
    | BtAdapterStateChanged BtAdapterState
    | BtGotDevices (List BtDevice)
    | BtConnected BtSocketId
    | BtConnectionFailure String
    | BtDisconnectSuccess BtSocketId
    | BtDisconnectFailure String
    | BtSendSuccess Int
    | BtSendFailure String
    | BtRecieved (Int, (List Int))
    | BtRecieveError String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputSendMsg txt ->
            ( { model | sendMsg = txt }
            , Cmd.none
            )

        ValidateSndMsg ->
            case hexStrToAsciiList model.sendMsg of
                Just intList ->
                    ( { model
                          | sendMsg = intList
                              |> validateSendMsg
                              |> asciiListToHexString
                              |> Maybe.andThen ((String.filter (\c -> c /= ' ')) >> Just)
                              |> Maybe.withDefault model.sendMsg
                      }
                    , Cmd.none
                    )
                Nothing ->
                    (model, Cmd.none)

        SendMsg ->
            case (model.btSocketId, hexStrToAsciiList model.sendMsg) of
                (Just sockId, Just sndmsg) ->
                    ( { model
                          | btCommunicationLog
                            = BtCommunicationLogItem Send sndmsg :: model.btCommunicationLog
                      }
                    , btSend (sockId, sndmsg)
                    )
                _ ->
                    (model, Cmd.none)

        Connect ->
            case model.selectedDevice of
                  Just dev ->
                      ( { model | btDevice = Just dev}
                      , btConnect dev.address
                      )
                  Nothing  ->
                      ( model, Cmd.none)

        Disconnect ->
            ( model
            , case model.btSocketId of
                  Just sockId ->
                      btDisconnect sockId
                  Nothing ->
                      Cmd.none
            )

        ClearResponse ->
            ( { model | btCommunicationLog = [] }
            , Cmd.none
            )

        SelectDevice device ->
            ( {model | selectedDevice = Just device}
            , Cmd.none
            )

        BtAdapterStateChanged  adapterState ->
            ( { model
                  | btAdapterState = Just adapterState
                  , btDevices = []
              }
            , if adapterState.powered
              then btGetDevices ()
              else Cmd.none
            )

        BtGotDevices devices ->
            ( { model | btDevices = devices }
            , Cmd.none
            )

        BtConnected socketId ->
            ( { model
                  | btSocketId = Just socketId
                  , statusText = "Connected : " ++
                    ( model.btDevice
                        |> Maybe.andThen .name
                        |> Maybe.withDefault ""
                    )
              }
            , Cmd.none
            )

        BtConnectionFailure errMsg ->
            ( { model
                  | btSocketId = Nothing
                  , btDevice   = Nothing
                  , statusText = "Connect Failed : " ++ errMsg
              }
            , Cmd.none
            )

        BtDisconnectSuccess _ ->
            ( { model
                  | btSocketId = Nothing
                  , btDevice   = Nothing
                  , statusText = "Disconnect : "
              }
            , Cmd.none
            )

        BtDisconnectFailure errMsg ->
            ( { model
                  | statusText = "Disconnect Failued : " ++ errMsg
              }
            , Cmd.none
            )

        BtSendSuccess nBytesSent ->
            ( { model
                  | statusText = "Sent " ++ (String.fromInt nBytesSent) ++ " bytes"
              }
            , Cmd.none
            )

        BtSendFailure errMsg ->
            ( { model
                  | statusText = "Sent Failed : " ++ errMsg
              }
            , Cmd.none
            )

        BtRecieved (nByteRecv, rcvData) ->
            ( { model
                  | btCommunicationLog
                    = BtCommunicationLogItem Recv rcvData :: model.btCommunicationLog
              }
            , Cmd.none
            )

        BtRecieveError errMsg ->
            ( { model
                  | statusText = "Recieve Error : " ++ errMsg
              }
            , Cmd.none
            )



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ btAdapterStateChanged BtAdapterStateChanged
        , btGotDevices BtGotDevices
        , btConnected BtConnected
        , btConnectionFailure BtConnectionFailure
        , btDisconnectSuccess BtDisconnectSuccess
        , btDisconnectFailure BtDisconnectFailure
        , btSendFailure BtSendFailure
        , btSendSuccess BtSendSuccess
        , btRecieved BtRecieved
        , btReceiveError BtRecieveError
        ]


view : Model -> Html Msg
view model =
    div [ style "display" "flex"
        , style "flex-direction" "column"
        , style "height" "100%"
        , style "box-sizing" "border-box"
        , style "padding" "1em"
        ]
        [ sendbox model
        , statusBox model
        , case model.btAdapterState of
              Nothing ->
                  div [] [ text "Bluetooth is turned off" ]
              Just adapterState ->
                  adapterStateView adapterState
        , btDevicesView model
        , motionPanels model
        , recieveView model
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
                 , onClick ValidateSndMsg
                 , disabled <| if model.sendMsg == "" then True else False
                 ]
            [ text "Validate" ]

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
                 , disabled <| if (model.selectedDevice == Nothing)
                               || (model.btSocketId /= Nothing)
                               then True
                               else False
                 ]
            [ text "Connect" ]
        , case model.btDevice of
              Just device -> text <|
                  " ["
                      ++ (if model.btSocketId == Nothing then "connecting.. " else" connected: ")
                      ++ (device.name |> Maybe.withDefault "")
                      ++ "]"
              Nothing ->
                  text ""
        ]

btDevicesView : Model -> Html Msg
btDevicesView model =
    div [] <|
    List.map (\d -> div [ onClick (SelectDevice d)
                        , style "background-color" (if Just d == model.selectedDevice then "pink" else "inherit")
                        ]
                  [ d.paired    |> Maybe.withDefault False |> (\p -> if p then "P" else "-") |> text
                  , d.connected |> Maybe.withDefault False |> (\p -> if p then "C" else "-") |> text
                  , text " "
                  , text d.address
                  , text " : "
                  , d.name |> Maybe.withDefault "" |> text
                  ])
        model.btDevices


recieveView : Model -> Html Msg
recieveView model =
    div [ style "overflow" "auto"
        , style "flex-grow" "1"
        , style "border" "3px dotted gray"
        ]
        (List.map logItemView model.btCommunicationLog |> List.reverse)

logItemView : BtCommunicationLogItem -> Html Msg
logItemView commLog =
    div []
        [ text <| case commLog.direction of
                      Send -> " > "
                      Recv -> " < "
        , commLog.message
            |> asciiListToHexString
            |> Maybe.withDefault "(Invalid Format)"
            |> text
        ]


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

motionPanels : Model -> Html Msg
motionPanels model =
    div [ style "display" "flex"
        , style "flex-wrap" "wrap"
        ]
         [ motionItem "051F003D27" "ホーム" model
         , motionItem "051F003E24" "どうぞ" model
         , motionItem "051F003F25" "ワクワク" model
         , motionItem "051F00405A" "コシニテ" model
         , motionItem "051F00415B" "ようこそ" model
         , motionItem "051F004258" "おねがい" model
         , motionItem "051F004359" "バイバイ" model
         , motionItem "051F00445E" "右にキス" model
         , motionItem "051F00455F" "左にキス" model
         , motionItem "051F00465C" "ピストル" model
         , motionItem "051F00475D" "敬礼" model
         , motionItem "051F004852" "え～ん" model
         , motionItem "051F004953" "ハート" model
         , motionItem "051F004A50" "キラッ" model
         , motionItem "051F004B51" "あなたへ" model
         , motionItem "051F004C56" "もんきー" model
         , motionItem "051F004D57" "GOx2" model
         , motionItem "051F004E54" "エアギター" model
         , motionItem "051F004F55" "右ターン" model
         , motionItem "051F00504A" "左ターン" model
         , motionItem "051F00011B" "ダンス再生" model
         , motionItem "051E00051E" "Lチカ" model
         , motionItem "04050001" "モーション停止" model
         ]

motionItem : String -> String -> Model -> Html Msg
motionItem hex name model =
    let
        ifSelected = \th el ->  if hex == model.sendMsg then th else el
    in
        div [ onClick (InputSendMsg hex)
            , style "height" "3em"
            , style "width" "5em"
            , style "margin" "2px"
            , style "border" <| ifSelected "3px dotted red" "3px dotted silver"
            , style "background-color" <| ifSelected "pink" "inherit"
            ]
        [ text name ]


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

asciiListToHexString : List Int -> Maybe String
asciiListToHexString asciis =
    asciiListToHexString_ asciis []


asciiListToHexString_ : List Int -> List Char -> Maybe String
asciiListToHexString_ asciis acc =
    case asciis of
        x :: xs ->
            case ( x // 16 |> intToHexChar
                 , x |> modBy 16 |> intToHexChar
                 )
            of
                (Just a, Just b) ->
                    asciiListToHexString_ xs  (b :: a :: ' ' :: acc)
                _ ->
                    Nothing
        [] ->
            acc |> List.reverse |> String.fromList  |> Just


intToHexChar : Int -> Maybe Char
intToHexChar i =
    case i of
         0  -> Just '0'
         1  -> Just '1'
         2  -> Just '2'
         3  -> Just '3'
         4  -> Just '4'
         5  -> Just '5'
         6  -> Just '6'
         7  -> Just '7'
         8  -> Just '8'
         9  -> Just '9'
         10 -> Just 'A'
         11 -> Just 'B'
         12 -> Just 'C'
         13 -> Just 'D'
         14 -> Just 'E'
         15 -> Just 'F'
         _  -> Nothing


validateSendMsg : List Int -> List Int
validateSendMsg msg =
    case msg of
        _ :: tail ->
            let
                len  = List.length msg
                body = List.take (len - 2) tail
                cb   = calculateCheckByte (len :: body)
            in
                len :: (body ++ [cb])
        [] -> []

calculateCheckByte : List Int -> Int
calculateCheckByte bytes =
    List.foldl xor 0 bytes
