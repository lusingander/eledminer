port module Home exposing (main)

import Browser
import Html exposing (Html, article, button, div, footer, h1, h2, header, i, input, label, option, p, section, select, span, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import Json.Encode as JE


port loaded : () -> Cmd msg


port openConnection : JE.Value -> Cmd msg


port saveNewConnection : JE.Value -> Cmd msg


port loadConnections : (JD.Value -> msg) -> Sub msg


port saveNewConnectionSuccess : (JD.Value -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { savedConnections : List ConnectionSetting
    , uiStatus : UIStatus
    , connectionModalInput : ConnectionSetting
    , errorStatus : ErrorStatus
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( initModel
    , loaded ()
    )


initModel : Model
initModel =
    { savedConnections = []
    , uiStatus = initUIStatus
    , connectionModalInput = initConnectionSetting
    , errorStatus = initErrorStatus
    }


type alias UIStatus =
    { newConenctionModalOpen : Bool
    }


initUIStatus : UIStatus
initUIStatus =
    { newConenctionModalOpen = False
    }


type alias ConnectionSetting =
    { system : String
    , name : String
    , hostname : String
    , portStr : String
    , username : String
    , password : String
    }


initConnectionSetting : ConnectionSetting
initConnectionSetting =
    { system = "server"
    , name = ""
    , hostname = ""
    , portStr = ""
    , username = ""
    , password = ""
    }


connectionSettingListDecoder : JD.Decoder (List ConnectionSetting)
connectionSettingListDecoder =
    JD.list connectionSettingDecoder


connectionSettingDecoder : JD.Decoder ConnectionSetting
connectionSettingDecoder =
    JD.map6 ConnectionSetting
        (JD.field "driver" JD.string)
        (JD.field "name" JD.string)
        (JD.field "hostname" JD.string)
        (JD.field "port" JD.string)
        (JD.field "username" JD.string)
        (JD.field "password" JD.string)


encodeConnectionSetting : ConnectionSetting -> JE.Value
encodeConnectionSetting s =
    JE.object
        [ ( "driver", JE.string s.system )
        , ( "name", JE.string s.name )
        , ( "hostname", JE.string s.hostname )
        , ( "port", JE.string s.portStr )
        , ( "username", JE.string s.username )
        , ( "password", JE.string s.password )
        ]


validConnectionSetting : ConnectionSetting -> Bool
validConnectionSetting s =
    let
        isNotEmpty =
            not << String.isEmpty
    in
    isNotEmpty s.name
        && isNotEmpty s.hostname
        && validPort s.portStr
        && isNotEmpty s.username
        && isNotEmpty s.password


validPort : String -> Bool
validPort =
    String.toInt >> Maybe.withDefault 0 >> (<) 0


serverName : ConnectionSetting -> String
serverName s =
    s.hostname ++ ":" ++ s.portStr


type alias ErrorStatus =
    { errorModalOpen : Bool
    , lastErrorMessage : String
    }


initErrorStatus : ErrorStatus
initErrorStatus =
    { errorModalOpen = False
    , lastErrorMessage = ""
    }


type Msg
    = OnClickLogin
    | LoadConnections (Result JD.Error (List ConnectionSetting))
    | SaveNewConnection
    | SaveNewConnectionSuccess (Result JD.Error ConnectionSetting)
    | OpenNewConnectionModal
    | CloseNewConnectionModal
    | OnChangeConnectionSystem String
    | OnChangeConnectionName String
    | OnChangeConnectionHostname String
    | OnChangeConnectionPort String
    | OnChangeConnectionUsername String
    | OnChangeConnectionPassword String
    | CloseErrorModal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        uiStatus =
            model.uiStatus

        connectionModalInput =
            model.connectionModalInput
    in
    case msg of
        OnClickLogin ->
            ( model
            , openConnection <| encodeConnectionSetting connectionModalInput
            )

        LoadConnections (Ok conns) ->
            ( { model
                | savedConnections = conns
              }
            , Cmd.none
            )

        LoadConnections (Err e) ->
            ( { model
                | errorStatus =
                    { errorModalOpen = True
                    , lastErrorMessage = JD.errorToString e
                    }
              }
            , Cmd.none
            )

        SaveNewConnection ->
            ( model
            , saveNewConnection <| encodeConnectionSetting connectionModalInput
            )

        SaveNewConnectionSuccess (Ok conn) ->
            update
                CloseNewConnectionModal
                { model
                    | savedConnections = conn :: model.savedConnections
                    , connectionModalInput = initConnectionSetting
                }

        SaveNewConnectionSuccess (Err e) ->
            ( { model
                | errorStatus =
                    { errorModalOpen = True
                    , lastErrorMessage = JD.errorToString e
                    }
              }
            , Cmd.none
            )

        OpenNewConnectionModal ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | newConenctionModalOpen = True
                    }
              }
            , Cmd.none
            )

        CloseNewConnectionModal ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | newConenctionModalOpen = False
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionSystem s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | system = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionName s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | name = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionHostname s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | hostname = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionPort s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | portStr = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionUsername s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | username = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionPassword s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | password = s
                    }
              }
            , Cmd.none
            )

        CloseErrorModal ->
            let
                errorStatus =
                    .errorStatus model
            in
            ( { model
                | errorStatus =
                    { errorStatus
                        | errorModalOpen = False
                    }
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ loadConnections (JD.decodeValue connectionSettingListDecoder)
            |> Sub.map LoadConnections
        , saveNewConnectionSuccess (JD.decodeValue connectionSettingDecoder)
            |> Sub.map SaveNewConnectionSuccess
        ]


view : Model -> Html Msg
view model =
    div []
        [ viewErrorModal model
        , viewHeader
        , viewConnections model
        , viewNewConnectionModal model
        ]


viewErrorModal : Model -> Html Msg
viewErrorModal model =
    div [ class "modal", classIsActive <| model.errorStatus.errorModalOpen ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-content" ]
            [ article [ class "message is-danger" ]
                [ div [ class "message-header" ]
                    [ p [] [ text "Error" ]
                    , button [ onClick CloseErrorModal, class "delete" ] []
                    ]
                , div [ class "message-body" ]
                    [ text model.errorStatus.lastErrorMessage ]
                ]
            ]
        ]


viewHeader : Html Msg
viewHeader =
    header [ class "hero is-light" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ h1 [ class "title is-3" ]
                    [ text "Home" ]
                ]
            ]
        ]


viewConnections : Model -> Html Msg
viewConnections model =
    section [ class "section" ]
        [ div [ class "container" ]
            [ viewConnectionsHeader
            , viewConnectionCards model
            ]
        ]


viewConnectionsHeader : Html Msg
viewConnectionsHeader =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ h2 [ class "title is-4 level-item" ]
                [ text "Connections" ]
            ]
        , div [ class "level-right" ]
            [ button
                [ class "button is-primary is-small is-rounded level-item"
                , onClick OpenNewConnectionModal
                ]
                [ text "New Connection" ]
            ]
        ]


viewConnectionCards : Model -> Html Msg
viewConnectionCards model =
    div [ class "columns is-multiline" ]
        (List.map buildConnectionCard model.savedConnections)


buildConnectionCard : ConnectionSetting -> Html Msg
buildConnectionCard s =
    viewConnectionCard s.name s.system (serverName s) s.username


viewConnectionCard : String -> String -> String -> String -> Html Msg
viewConnectionCard name system host user =
    div [ class "column is-one-third" ]
        [ div [ class "card" ]
            [ div [ class "card-content" ]
                [ div [ class "content is-small" ]
                    [ viewConnectionCardHeader name
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-database" ] [] ], text system ]
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-network-wired" ] [] ], text host ]
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-user" ] [] ], text user ]
                    ]
                ]
            ]
        ]


viewConnectionCardHeader : String -> Html Msg
viewConnectionCardHeader name =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ p [ class "title is-6 card-icon-title" ] [ text name ]
            ]
        , div [ class "level-right" ]
            [ span [ class "icon card-icon-edit" ] [ i [ class "fas fa-edit" ] [] ]
            , span [ class "icon card-icon-danger" ] [ i [ class "fas fa-window-close" ] [] ]
            ]
        ]


viewNewConnectionModal : Model -> Html Msg
viewNewConnectionModal model =
    div [ class "modal", classIsActive <| model.uiStatus.newConenctionModalOpen ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "New Connection" ] ]
            , section [ class "modal-card-body" ]
                [ viewNewConnectionModalContent model
                ]
            , footer [ class "modal-card-foot" ]
                [ button
                    [ onClick SaveNewConnection
                    , class "button is-primary"
                    , disabled <| not <| validConnectionSetting model.connectionModalInput
                    ]
                    [ text "OK" ]
                , button
                    [ onClick CloseNewConnectionModal
                    , class "button is-light"
                    ]
                    [ text "Cancel" ]
                ]
            ]
        ]


viewNewConnectionModalContent : Model -> Html Msg
viewNewConnectionModalContent model =
    let
        conn =
            model.connectionModalInput
    in
    div [ class "container" ]
        [ viewHorizontalSystemSelect "System"
        , viewHorizontalTextInputField "Connection Name" conn.name OnChangeConnectionName
        , viewHorizontalTextInputField "Hostname" conn.hostname OnChangeConnectionHostname
        , viewHorizontalNumberInputField "Port" conn.portStr OnChangeConnectionPort
        , viewHorizontalTextInputField "Username" conn.username OnChangeConnectionUsername
        , viewHorizontalPasswordInputField "Password" conn.password OnChangeConnectionPassword
        ]


viewHorizontalSystemSelect : String -> Html Msg
viewHorizontalSystemSelect labelText =
    viewHorizontalComponent labelText [ viewSystemSelect ]


viewSystemSelect : Html Msg
viewSystemSelect =
    let
        handler selected =
            OnChangeConnectionSystem selected
    in
    div [ class "select is-small" ]
        [ select
            [ onChange handler
            ]
            (List.map
                (\( n, v ) -> option [ value v ] [ text n ])
                systemNameAndDrivers
            )
        ]


onChange : (String -> msg) -> Html.Attribute msg
onChange handler =
    Html.Events.on "change" (JD.map handler Html.Events.targetValue)


systemNameAndDrivers : List ( String, String )
systemNameAndDrivers =
    [ ( "MySQL", "server" )
    , ( "SQLite 3", "sqlite" )
    , ( "SQLite 2", "sqlite2" )
    , ( "PostgreSQL", "pgsql" )
    , ( "Oravle (beta)", "oracle" )
    , ( "MS SQL (beta)", "mssql" )
    , ( "Firebird (alpha)", "firebird" )
    , ( "SimpleDB", "simpledb" )
    , ( "Elasticsearch (beta)", "elastic" )
    , ( "ClickHouse (alpha)", "clickhouse" )
    ]


viewHorizontalTextInputField : String -> String -> (String -> Msg) -> Html Msg
viewHorizontalTextInputField =
    viewHorizontalInputField "text"


viewHorizontalPasswordInputField : String -> String -> (String -> Msg) -> Html Msg
viewHorizontalPasswordInputField =
    viewHorizontalInputField "password"


viewHorizontalNumberInputField : String -> String -> (String -> Msg) -> Html Msg
viewHorizontalNumberInputField =
    viewHorizontalInputField "number"


viewHorizontalInputField : String -> String -> String -> (String -> Msg) -> Html Msg
viewHorizontalInputField inputType labelText inputValue inputMsg =
    viewHorizontalComponent labelText
        [ p [ class "control" ]
            [ input
                [ class "input is-small"
                , type_ inputType
                , value inputValue
                , onInput inputMsg
                ]
                []
            ]
        ]


viewHorizontalComponent : String -> List (Html Msg) -> Html Msg
viewHorizontalComponent labelText children =
    div [ class "field is-horizontal" ]
        [ div [ class "field-label is-small" ]
            [ label [ class "label" ] [ text labelText ] ]
        , div [ class "field-body" ]
            [ div [ class "field" ]
                children
            ]
        ]


classIsActive : Bool -> Html.Attribute Msg
classIsActive active =
    if active then
        class "is-active"

    else
        class ""
