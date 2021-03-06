port module Home exposing (main)

import Browser
import Connection as C
import Html exposing (Html, a, article, button, div, footer, h1, h2, header, i, input, label, option, p, section, select, span, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Html.Keyed
import Html.Lazy
import Json.Decode as JD
import Json.Encode as JE
import List.Extra
import Random
import Task
import Time
import UUID


port loaded : () -> Cmd msg


port openConnection : JE.Value -> Cmd msg


port saveNewConnection : JE.Value -> Cmd msg


port saveEditConnection : JE.Value -> Cmd msg


port removeConnection : JE.Value -> Cmd msg


port openAdminerHome : () -> Cmd msg


port openSqliteFileDialog : () -> Cmd msg


port openConnectionComplete : (() -> msg) -> Sub msg


port openConnectionFailure : (() -> msg) -> Sub msg


port loadConnections : (JD.Value -> msg) -> Sub msg


port saveNewConnectionSuccess : (JD.Value -> msg) -> Sub msg


port saveEditConnectionSuccess : (JD.Value -> msg) -> Sub msg


port removeConnectionSuccess : (JD.Value -> msg) -> Sub msg


port openSqliteFileDialogSuccess : (JD.Value -> msg) -> Sub msg


port phpServerNotRunning : (() -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { connections : List C.Connection
    , uiStatus : UIStatus
    , connectionModalInput : C.ConnectionFields
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
    , connectionModalInput = C.initConnectionFields
    }


type alias UIStatus =
    { conenctionModalOpen : Bool
    , isNewConnectionModal : Bool
    , confirmRemoveConnectionModalOpen : Bool
    , confirmRemoveConnectionModalTarget : ( String, String )
    , loaderActive : Bool
    , passwordInputModalOpen : Bool
    , passwordInputModalInput : String
    , passwordInputModalTemporaryConnection : C.Connection
    , errorModalOpen : Bool
    , lastErrorMessage : String
    }


initUIStatus : UIStatus
initUIStatus =
    { conenctionModalOpen = False
    , isNewConnectionModal = True
    , confirmRemoveConnectionModalOpen = False
    , confirmRemoveConnectionModalTarget = ( "", "" )
    , loaderActive = False
    , passwordInputModalOpen = False
    , passwordInputModalInput = ""
    , passwordInputModalTemporaryConnection = C.emptyConnection
    , errorModalOpen = False
    , lastErrorMessage = ""
    }


validConnection : C.Connection -> Bool
validConnection c =
    case c of
        C.DefaultConnection s ->
            isNotEmpty s.name
                && isNotEmpty s.hostname
                && validPort s.portStr
                && isNotEmpty s.username
                && validPassword s

        C.SqliteConnection s ->
            isNotEmpty s.name
                && isNotEmpty s.filepath


validPort : String -> Bool
validPort =
    String.toInt >> Maybe.withDefault 0 >> (<) 0


validPassword : C.DefaultConnectionSetting -> Bool
validPassword s =
    if s.savePassword then
        isNotEmpty s.password

    else
        True


isNotEmpty : String -> Bool
isNotEmpty =
    not << String.isEmpty


serverName : C.DefaultConnectionSetting -> String
serverName s =
    s.hostname ++ ":" ++ s.portStr


databaseName : C.Connection -> String
databaseName c =
    List.Extra.find (\( _, v ) -> v == C.system c) systemNameAndDrivers
        |> Maybe.map (\( v, _ ) -> v)
        |> Maybe.withDefault ""


type Msg
    = OpenConnection String
    | OpenInputPasswordModal C.Connection
    | OnChangeInputPasswordModalPassword String
    | SubmitInputPassword String
    | CancelInputPassword
    | OpenConnectionComplete
    | OpenConnectionFailure
    | LoadConnections (Result JD.Error (List C.Connection))
    | OnClickSaveNewConnection
    | SaveNewConnection String
    | SaveNewConnectionSuccess (Result JD.Error C.Connection)
    | SaveEditConnection
    | SaveEditConnectionSuccess (Result JD.Error C.Connection)
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
    | OnChangeConnectionFilepath String
    | OnClickSavePassword
    | OpenSqliteFileDialog
    | OpenSqliteFileDialogSuccess (Result JD.Error String)
    | CloseErrorModal
    | PhpServerNotRunning


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        uiStatus =
            model.uiStatus

        connectionModalInput =
            model.connectionModalInput
    in
    case msg of
        OpenConnection id ->
            let
                selected =
                    List.Extra.find (\c -> C.id c == id) model.connections
            in
            case selected of
                Just conn ->
                    if needToInputPassword conn then
                        update (OpenInputPasswordModal conn) model

                    else
                        ( showLoader model
                        , openConnection <| C.encodeConnection <| conn
                        )

                Nothing ->
                    ( showErrorModal ("Connection id is not found: =" ++ id) model
                    , Cmd.none
                    )

        OpenInputPasswordModal conn ->
            ( showPasswordInputModal conn model
            , Cmd.none
            )

        OnChangeInputPasswordModalPassword s ->
            ( { model
                | uiStatus =
                    { uiStatus
                        | passwordInputModalInput = s
                    }
              }
            , Cmd.none
            )

        SubmitInputPassword password ->
            ( showLoader model |> closePasswordInputModal
            , openConnection <| C.encodeConnection <| C.setPassword password <| model.uiStatus.passwordInputModalTemporaryConnection
            )

        CancelInputPassword ->
            ( closePasswordInputModal model
            , Cmd.none
            )

        OpenConnectionComplete ->
            ( hideLoader model
            , Cmd.none
            )

        OpenConnectionFailure ->
            ( showErrorModal "Failed to connect" model
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

        OnClickSaveNewConnection ->
            ( model
            , Task.perform SaveNewConnection <| Task.map UUID.toString newUUID
            )

        SaveNewConnection id ->
            ( model
            , saveNewConnection <| C.encodeConnection <| C.toConnection { connectionModalInput | id = id }
            )

        SaveNewConnectionSuccess (Ok conn) ->
            update
                CloseConnectionModal
                { model
                    | connections = conn :: model.connections
                    , connectionModalInput = C.initConnectionFields
                }

        SaveNewConnectionSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        SaveEditConnection ->
            ( model
            , saveEditConnection <| C.encodeConnection <| C.toConnection connectionModalInput
            )

        SaveEditConnectionSuccess (Ok conn) ->
            update
                CloseConnectionModal
                { model
                    | connections = List.Extra.updateIf (\c -> C.id c == C.id conn) (\_ -> conn) model.connections
                    , connectionModalInput = C.initConnectionFields
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
                    | connections = List.filter (\c -> C.id c /= id) model.connections
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
                        C.initConnectionFields
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
                    List.Extra.find (\c -> C.id c == id) model.connections
                        |> Maybe.withDefault C.emptyConnection
                        |> C.toConnectionFields
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

        OnChangeConnectionFilepath s ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | filepath = s
                    }
              }
            , Cmd.none
            )

        OnClickSavePassword ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | savePassword = Maybe.map not connectionModalInput.savePassword
                    }
              }
            , Cmd.none
            )

        OpenSqliteFileDialog ->
            ( model
            , openSqliteFileDialog ()
            )

        OpenSqliteFileDialogSuccess (Ok path) ->
            ( { model
                | connectionModalInput =
                    { connectionModalInput
                        | filepath = path
                    }
              }
            , Cmd.none
            )

        OpenSqliteFileDialogSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        CloseErrorModal ->
            ( closeErrorModal model
            , Cmd.none
            )

        PhpServerNotRunning ->
            ( hideLoader model
                |> showErrorModal "PHP Server is not running. Check the PHP executable path in the settings page."
            , Cmd.none
            )


showLoader : Model -> Model
showLoader model =
    let
        uiStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { uiStatus
                | loaderActive = True
            }
    }


hideLoader : Model -> Model
hideLoader model =
    let
        uiStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { uiStatus
                | loaderActive = False
            }
    }


showPasswordInputModal : C.Connection -> Model -> Model
showPasswordInputModal c model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | passwordInputModalOpen = True
                , passwordInputModalInput = ""
                , passwordInputModalTemporaryConnection = c
            }
    }


closePasswordInputModal : Model -> Model
closePasswordInputModal model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | passwordInputModalOpen = False
                , passwordInputModalInput = ""
                , passwordInputModalTemporaryConnection = C.emptyConnection
            }
    }


showErrorModal : String -> Model -> Model
showErrorModal message model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | errorModalOpen = True
                , lastErrorMessage = message
            }
    }


closeErrorModal : Model -> Model
closeErrorModal model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | errorModalOpen = False
            }
    }


newUUID : Task.Task Never UUID.UUID
newUUID =
    Task.map (Tuple.first << Random.step UUID.generator << Random.initialSeed << Time.posixToMillis) Time.now


needToInputPassword : C.Connection -> Bool
needToInputPassword c =
    case c of
        C.DefaultConnection s ->
            String.isEmpty s.password

        _ ->
            False


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ openConnectionComplete (\_ -> OpenConnectionComplete)
        , openConnectionFailure (\_ -> OpenConnectionFailure)
        , loadConnections (JD.decodeValue C.connectionsDecoder)
            |> Sub.map LoadConnections
        , saveNewConnectionSuccess (JD.decodeValue C.connectionDecoder)
            |> Sub.map SaveNewConnectionSuccess
        , saveEditConnectionSuccess (JD.decodeValue C.connectionDecoder)
            |> Sub.map SaveEditConnectionSuccess
        , removeConnectionSuccess (JD.decodeValue JD.string)
            |> Sub.map RemoveConnectionSuccess
        , openSqliteFileDialogSuccess (JD.decodeValue JD.string)
            |> Sub.map OpenSqliteFileDialogSuccess
        , phpServerNotRunning (\_ -> PhpServerNotRunning)
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
    , viewPasswordInputModal model
    , viewConnectionModal model
    , viewConfirmRemoveConnectionModal model
    , viewLoader model
    ]


viewErrorModal : Model -> Html Msg
viewErrorModal model =
    div [ class "modal", classIsActive <| model.uiStatus.errorModalOpen ]
        [ div [ class "modal-background", onClick CloseErrorModal ] []
        , div [ class "modal-content" ]
            [ article [ class "message is-danger" ]
                [ div [ class "message-header" ]
                    [ p [] [ text "Error" ]
                    , button [ onClick CloseErrorModal, class "delete" ] []
                    ]
                , div [ class "message-body" ]
                    [ text model.uiStatus.lastErrorMessage ]
                ]
            ]
        ]


viewPasswordInputModal : Model -> Html Msg
viewPasswordInputModal model =
    div [ class "modal", classIsActive <| model.uiStatus.passwordInputModalOpen ]
        [ div [ class "modal-background", onClick CancelInputPassword ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "Confirm" ] ]
            , section [ class "modal-card-body" ]
                [ div [ class "container" ]
                    [ viewHorizontalPasswordInputField "Password" model.uiStatus.passwordInputModalInput OnChangeInputPasswordModalPassword
                    ]
                ]
            , footer [ class "modal-card-foot" ]
                [ button
                    [ onClick <| SubmitInputPassword model.uiStatus.passwordInputModalInput
                    , class "button is-primary"
                    ]
                    [ text "OK" ]
                , button
                    [ onClick CancelInputPassword
                    , class "button is-light"
                    ]
                    [ text "Cancel" ]
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


buildConnectionCard : C.Connection -> ( String, Html Msg )
buildConnectionCard c =
    case c of
        C.DefaultConnection s ->
            ( s.id
            , Html.Lazy.lazy viewDefaultConnectionCard
                { id = s.id
                , name = s.name
                , db = databaseName c
                , server = serverName s
                , user = s.username
                }
            )

        C.SqliteConnection s ->
            ( s.id
            , Html.Lazy.lazy viewSqliteConnectionCard
                { id = s.id
                , name = s.name
                , db = databaseName c
                , path = s.filepath
                }
            )


type alias ViewDefaultConnectionCardParameter =
    { id : String
    , name : String
    , db : String
    , server : String
    , user : String
    }


viewDefaultConnectionCard : ViewDefaultConnectionCardParameter -> Html Msg
viewDefaultConnectionCard { id, name, db, server, user } =
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


type alias ViewSqliteConnectionCardParameter =
    { id : String
    , name : String
    , db : String
    , path : String
    }


viewSqliteConnectionCard : ViewSqliteConnectionCardParameter -> Html Msg
viewSqliteConnectionCard { id, name, db, path } =
    div [ class "column is-one-third" ]
        [ div [ class "card" ]
            [ div [ class "card-content" ]
                [ div [ class "content is-small" ]
                    [ viewConnectionCardHeader id name
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-database" ] [] ], text db ]
                    , p [] [ span [ class "icon" ] [ i [ class "fas fa-folder-open" ] [] ], text path ]
                    , p [] [ span [ class "icon is-invisible" ] [ i [ class "fas fa-user" ] [] ] ]
                    ]
                ]
            ]
        ]


viewConnectionCardHeader : String -> String -> Html Msg
viewConnectionCardHeader id name =
    div [ class "level" ]
        [ div [ class "level-left" ]
            [ p [ onClick <| OpenConnection id, class "title is-6 card-icon-title" ] [ text name ]
            ]
        , div [ class "level-right" ]
            [ span [ onClick <| OpenEditConnectionModal id, class "icon card-icon-edit" ] [ i [ class "fas fa-edit" ] [] ]
            , span [ onClick <| OpenConfirmRemoveConnectionModal ( id, name ), class "icon card-icon-danger" ] [ i [ class "fas fa-window-close" ] [] ]
            ]
        ]


viewConnectionModal : Model -> Html Msg
viewConnectionModal model =
    if model.uiStatus.isNewConnectionModal then
        viewConnectionModalBase "New Connection" OnClickSaveNewConnection model

    else
        viewConnectionModalBase "Edit Connection" SaveEditConnection model


viewConnectionModalBase : String -> Msg -> Model -> Html Msg
viewConnectionModalBase title ok model =
    div [ class "modal", classIsActive <| model.uiStatus.conenctionModalOpen ]
        [ div [ class "modal-background", onClick CloseConnectionModal ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text title ] ]
            , section [ class "modal-card-body" ]
                [ viewConnectionModalContent model
                ]
            , footer [ class "modal-card-foot" ]
                [ button
                    [ onClick ok
                    , class "button is-primary"
                    , disabled <| not <| validConnection <| C.toConnection model.connectionModalInput
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


viewConnectionModalContent : Model -> Html Msg
viewConnectionModalContent model =
    case C.toConnection model.connectionModalInput of
        C.DefaultConnection s ->
            div [ class "container" ]
                [ viewHorizontalSystemSelect "System" s.system
                , viewHorizontalTextInputField "Name" s.name OnChangeConnectionName
                , viewHorizontalTextInputField "Hostname" s.hostname OnChangeConnectionHostname
                , viewHorizontalNumberInputField "Port" s.portStr OnChangeConnectionPort
                , viewHorizontalTextInputField "Username" s.username OnChangeConnectionUsername
                , viewPasswordInput s.password s.savePassword
                ]

        C.SqliteConnection s ->
            div [ class "container" ]
                [ viewHorizontalSystemSelect "System" s.system
                , viewHorizontalTextInputField "Name" s.name OnChangeConnectionName
                , viewFilepathInput s.filepath
                ]


viewFilepathInput : String -> Html Msg
viewFilepathInput filepath =
    viewHorizontalAddonsTextInputField
        "File Path"
        filepath
        OnChangeConnectionFilepath
        (span [] [ i [ class "fas fa-folder-open" ] [] ])
        OpenSqliteFileDialog


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


viewPasswordInput : String -> Bool -> Html Msg
viewPasswordInput password savePassword =
    let
        check =
            if savePassword then
                i [ class "fas fa-lg fa-check-square" ] []

            else
                i [ class "fas fa-lg fa-square" ] []
    in
    viewHorizontalAddonsPasswordInputField
        (not savePassword)
        "Password"
        password
        OnChangeConnectionPassword
        (span [] [ span [ class "icon is-medium" ] [ check ], span [] [ text " Save Password" ] ])
        OnClickSavePassword


viewHorizontalAddonsPasswordInputField : Bool -> String -> String -> (String -> Msg) -> Html Msg -> Msg -> Html Msg
viewHorizontalAddonsPasswordInputField =
    viewHorizontalInputAddonsField "password"


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


viewHorizontalAddonsTextInputField : String -> String -> (String -> Msg) -> Html Msg -> Msg -> Html Msg
viewHorizontalAddonsTextInputField =
    viewHorizontalInputAddonsField "text" False


viewHorizontalInputAddonsField : String -> Bool -> String -> String -> (String -> Msg) -> Html Msg -> Msg -> Html Msg
viewHorizontalInputAddonsField inputType inputDisabled labelText inputValue inputMsg buttonContent buttonMsg =
    viewHorizontalAddonsComponent labelText
        [ p [ class "control is-expanded" ]
            [ input
                [ class "input is-small"
                , type_ inputType
                , value inputValue
                , onInput inputMsg
                , disabled inputDisabled
                ]
                []
            ]
        , p [ class "control", onClick buttonMsg ]
            [ a [ class "button is-link is-small" ] [ buttonContent ]
            ]
        ]


viewHorizontalAddonsComponent : String -> List (Html Msg) -> Html Msg
viewHorizontalAddonsComponent labelText children =
    div [ class "field is-horizontal" ]
        [ div [ class "field-label is-small" ]
            [ label [ class "label" ] [ text labelText ] ]
        , div [ class "field-body" ]
            [ div [ class "field has-addons" ]
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
        [ div [ class "modal-background", onClick CloseConfirmRemoveConnectionModal ] []
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
