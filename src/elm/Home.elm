port module Home exposing (main)

import Browser
import Html exposing (Html, a, article, button, div, footer, h1, h2, header, i, input, label, option, p, section, select, span, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Html.Lazy
import Json.Decode as JD
import Json.Encode as JE
import List.Extra


port loaded : () -> Cmd msg


port openConnection : JE.Value -> Cmd msg


port saveNewConnection : JE.Value -> Cmd msg


port saveEditConnection : JE.Value -> Cmd msg


port removeConnection : JE.Value -> Cmd msg


port openAdminerHome : () -> Cmd msg


port openConnectionSuccess : (() -> msg) -> Sub msg


port loadConnections : (JD.Value -> msg) -> Sub msg


port saveNewConnectionSuccess : (JD.Value -> msg) -> Sub msg


port saveEditConnectionSuccess : (JD.Value -> msg) -> Sub msg


port removeConnectionSuccess : (JD.Value -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { connections : List ConnectionSetting
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
    { connections = []
    , uiStatus = initUIStatus
    , connectionModalInput = initConnectionSetting
    , errorStatus = initErrorStatus
    }


type alias UIStatus =
    { conenctionModalOpen : Bool
    , isNewConnectionModal : Bool
    , confirmRemoveConnectionModalOpen : Bool
    , confirmRemoveConnectionModalTarget : ( String, String )
    , loaderActive : Bool
    }


initUIStatus : UIStatus
initUIStatus =
    { conenctionModalOpen = False
    , isNewConnectionModal = True
    , confirmRemoveConnectionModalOpen = False
    , confirmRemoveConnectionModalTarget = ( "", "" )
    , loaderActive = False
    }


type alias ConnectionSetting =
    { id : String
    , system : String
    , name : String
    , hostname : String
    , portStr : String
    , username : String
    , password : String
    }


initConnectionSetting : ConnectionSetting
initConnectionSetting =
    { id = ""
    , system = "server"
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
    JD.map7 ConnectionSetting
        (JD.field "id" JD.string)
        (JD.field "driver" JD.string)
        (JD.field "name" JD.string)
        (JD.field "hostname" JD.string)
        (JD.field "port" JD.string)
        (JD.field "username" JD.string)
        (JD.field "password" JD.string)


encodeConnectionSetting : ConnectionSetting -> JE.Value
encodeConnectionSetting s =
    JE.object
        [ ( "id", JE.string s.id )
        , ( "driver", JE.string s.system )
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


databaseName : ConnectionSetting -> String
databaseName s =
    List.Extra.find (\( _, v ) -> v == s.system) systemNameAndDrivers
        |> Maybe.map (\( v, _ ) -> v)
        |> Maybe.withDefault ""


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
    = OnClickLogin String
    | OpenConnectionSuccess
    | LoadConnections (Result JD.Error (List ConnectionSetting))
    | SaveNewConnection
    | SaveNewConnectionSuccess (Result JD.Error ConnectionSetting)
    | SaveEditConnection
    | SaveEditConnectionSuccess (Result JD.Error ConnectionSetting)
    | RemoveConnection String
    | RemoveConnectionSuccess (Result JD.Error String)
    | OpenAdminerHome
    | OpenNewConnectionModal
    | OpenEditConnectionModal String
    | CloseConnectionModal
    | OpenConfirmRemoveConnectionModal ( String, String )
    | CloseConfirmRemoveConnectionModal
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
        OnClickLogin id ->
            let
                selected =
                    List.Extra.find (\c -> c.id == id) model.connections
            in
            case selected of
                Just conn ->
                    ( { model
                        | uiStatus =
                            { uiStatus
                                | loaderActive = True
                            }
                      }
                    , openConnection <| encodeConnectionSetting <| conn
                    )

                Nothing ->
                    ( showErrorModal ("Connection id is not found: =" ++ id) model
                    , Cmd.none
                    )

        OpenConnectionSuccess ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | loaderActive = False
                    }
              }
            , Cmd.none
            )

        LoadConnections (Ok conns) ->
            ( { model
                | connections = conns
              }
            , Cmd.none
            )

        LoadConnections (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        SaveNewConnection ->
            ( model
            , saveNewConnection <| encodeConnectionSetting connectionModalInput
            )

        SaveNewConnectionSuccess (Ok conn) ->
            update
                CloseConnectionModal
                { model
                    | connections = conn :: model.connections
                    , connectionModalInput = initConnectionSetting
                }

        SaveNewConnectionSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        SaveEditConnection ->
            ( model
            , saveEditConnection <| encodeConnectionSetting connectionModalInput
            )

        SaveEditConnectionSuccess (Ok conn) ->
            update
                CloseConnectionModal
                { model
                    | connections = List.Extra.updateIf (\c -> c.id == conn.id) (\_ -> conn) model.connections
                    , connectionModalInput = initConnectionSetting
                }

        SaveEditConnectionSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        RemoveConnection id ->
            ( model
            , removeConnection <| JE.string id
            )

        RemoveConnectionSuccess (Ok id) ->
            update
                CloseConfirmRemoveConnectionModal
                { model
                    | connections = List.filter (\c -> c.id /= id) model.connections
                }

        RemoveConnectionSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        OpenAdminerHome ->
            ( model
            , openAdminerHome ()
            )

        OpenNewConnectionModal ->
            let
                newConnectionModalInput =
                    if uiStatus.isNewConnectionModal then
                        model.connectionModalInput

                    else
                        initConnectionSetting
            in
            ( { model
                | uiStatus =
                    { uiStatus
                        | conenctionModalOpen = True
                        , isNewConnectionModal = True
                    }
                , connectionModalInput = newConnectionModalInput
              }
            , Cmd.none
            )

        OpenEditConnectionModal id ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | conenctionModalOpen = True
                        , isNewConnectionModal = False
                    }
                , connectionModalInput =
                    List.Extra.find (\c -> c.id == id) model.connections
                        |> Maybe.withDefault initConnectionSetting
              }
            , Cmd.none
            )

        CloseConnectionModal ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | conenctionModalOpen = False
                    }
              }
            , Cmd.none
            )

        OpenConfirmRemoveConnectionModal target ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | confirmRemoveConnectionModalOpen = True
                        , confirmRemoveConnectionModalTarget = target
                    }
              }
            , Cmd.none
            )

        CloseConfirmRemoveConnectionModal ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | confirmRemoveConnectionModalOpen = False
                        , confirmRemoveConnectionModalTarget = ( "", "" )
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
            ( closeErrorModal model
            , Cmd.none
            )


showErrorModal : String -> Model -> Model
showErrorModal message model =
    { model
        | errorStatus =
            { errorModalOpen = True
            , lastErrorMessage = message
            }
    }


closeErrorModal : Model -> Model
closeErrorModal model =
    { model
        | errorStatus =
            { errorModalOpen = False
            , lastErrorMessage = model.errorStatus.lastErrorMessage
            }
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ openConnectionSuccess (\_ -> OpenConnectionSuccess)
        , loadConnections (JD.decodeValue connectionSettingListDecoder)
            |> Sub.map LoadConnections
        , saveNewConnectionSuccess (JD.decodeValue connectionSettingDecoder)
            |> Sub.map SaveNewConnectionSuccess
        , saveEditConnectionSuccess (JD.decodeValue connectionSettingDecoder)
            |> Sub.map SaveEditConnectionSuccess
        , removeConnectionSuccess (JD.decodeValue JD.string)
            |> Sub.map RemoveConnectionSuccess
        ]


view : Model -> Html Msg
view model =
    div []
        (viewContents model ++ viewModals model)


viewContents : Model -> List (Html Msg)
viewContents model =
    [ viewHeader
    , viewConnections model
    , viewFooter
    ]


viewModals : Model -> List (Html Msg)
viewModals model =
    [ viewErrorModal model
    , viewConnectionModal model
    , viewConfirmRemoveConnectionModal model
    , viewLoader model
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
    Html.Keyed.node
        "div"
        [ class "columns is-multiline" ]
        (List.map buildConnectionCard model.connections)


buildConnectionCard : ConnectionSetting -> ( String, Html Msg )
buildConnectionCard s =
    ( s.id
    , Html.Lazy.lazy viewConnectionCard
        { id = s.id
        , name = s.name
        , db = databaseName s
        , server = serverName s
        , user = s.username
        }
    )


type alias ViewConnectionCardParameter =
    { id : String
    , name : String
    , db : String
    , server : String
    , user : String
    }


viewConnectionCard : ViewConnectionCardParameter -> Html Msg
viewConnectionCard { id, name, db, server, user } =
    div [ class "column is-one-third" ]
        [ div [ class "card" ]
            [ div [ class "card-content" ]
                [ div [ class "content is-small" ]
                    [ viewConnectionCardHeader id name
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-database" ] [] ], text db ]
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-network-wired" ] [] ], text server ]
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-user" ] [] ], text user ]
                    ]
                ]
            ]
        ]


viewConnectionCardHeader : String -> String -> Html Msg
viewConnectionCardHeader id name =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ p [ onClick <| OnClickLogin id, class "title is-6 card-icon-title" ] [ text name ]
            ]
        , div [ class "level-right" ]
            [ span [ onClick <| OpenEditConnectionModal id, class "icon card-icon-edit" ] [ i [ class "fas fa-edit" ] [] ]
            , span [ onClick <| OpenConfirmRemoveConnectionModal ( id, name ), class "icon card-icon-danger" ] [ i [ class "fas fa-window-close" ] [] ]
            ]
        ]


viewConnectionModal : Model -> Html Msg
viewConnectionModal model =
    if model.uiStatus.isNewConnectionModal then
        viewConnectionModalBase "New Connection" SaveNewConnection model

    else
        viewConnectionModalBase "Edit Connection" SaveEditConnection model


viewConnectionModalBase : String -> Msg -> Model -> Html Msg
viewConnectionModalBase title ok model =
    div [ class "modal", classIsActive <| model.uiStatus.conenctionModalOpen ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text title ] ]
            , section [ class "modal-card-body" ]
                [ viewNewConnectionModalContent model
                ]
            , footer [ class "modal-card-foot" ]
                [ button
                    [ onClick ok
                    , class "button is-primary"
                    , disabled <| not <| validConnectionSetting model.connectionModalInput
                    ]
                    [ text "OK" ]
                , button
                    [ onClick CloseConnectionModal
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
        [ viewHorizontalSystemSelect "System" conn.system
        , viewHorizontalTextInputField "Connection Name" conn.name OnChangeConnectionName
        , viewHorizontalTextInputField "Hostname" conn.hostname OnChangeConnectionHostname
        , viewHorizontalNumberInputField "Port" conn.portStr OnChangeConnectionPort
        , viewHorizontalTextInputField "Username" conn.username OnChangeConnectionUsername
        , viewHorizontalPasswordInputField "Password" conn.password OnChangeConnectionPassword
        ]


viewHorizontalSystemSelect : String -> String -> Html Msg
viewHorizontalSystemSelect labelText inputValue =
    viewHorizontalComponent labelText [ viewSystemSelect inputValue ]


viewSystemSelect : String -> Html Msg
viewSystemSelect inputValue =
    let
        handler selected =
            OnChangeConnectionSystem selected
    in
    div [ class "select is-small" ]
        [ select
            [ onChange handler
            , value inputValue
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
    , ( "Oracle (beta)", "oracle" )
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


viewConfirmRemoveConnectionModal : Model -> Html Msg
viewConfirmRemoveConnectionModal model =
    let
        open =
            model.uiStatus.confirmRemoveConnectionModalOpen

        ( id, name ) =
            model.uiStatus.confirmRemoveConnectionModalTarget
    in
    div [ class "modal", classIsActive <| open ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "Confirm" ] ]
            , section [ class "modal-card-body" ]
                [ div [] [ text <| "Do you want to remove connection " ++ name ++ "?" ] ]
            , footer [ class "modal-card-foot" ]
                [ button [ onClick <| RemoveConnection id, class "button is-danger" ] [ text "OK" ]
                , button [ onClick CloseConfirmRemoveConnectionModal, class "button is-light" ] [ text "Cancel" ]
                ]
            ]
        ]


viewFooter : Html Msg
viewFooter =
    div [ class "container" ]
        [ div [ class "is-pulled-right" ]
            [ a [ onClick OpenAdminerHome ] [ text "Adminer home" ] ]
        ]


viewLoader : Model -> Html Msg
viewLoader model =
    div [ class "loader-wrapper", classIsActive model.uiStatus.loaderActive ]
        [ div [ class "loader is-loading" ] [] ]
