port module Home exposing (main)

import Browser
import Html exposing (Html, button, div, footer, h1, h2, header, input, label, option, p, section, select, text)
import Html.Attributes exposing (class, disabled, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import Json.Encode as JE


port openConnection : JE.Value -> Cmd msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { uiStatus : UIStatus
    , connectionSetting : ConnectionSetting
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( initModel
    , Cmd.none
    )


initModel : Model
initModel =
    { uiStatus = initUIStatus
    , connectionSetting = initConnectionSetting
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


encodeConnectionSetting : ConnectionSetting -> JE.Value
encodeConnectionSetting s =
    JE.object
        [ ( "driver", JE.string s.system )
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


type Msg
    = OnClickLogin
    | OpenNewConnectionModal
    | CloseNewConnectionModal
    | OnChangeConnectionSystem String
    | OnChangeConnectionName String
    | OnChangeConnectionHostname String
    | OnChangeConnectionPort String
    | OnChangeConnectionUsername String
    | OnChangeConnectionPassword String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        uiStatus =
            model.uiStatus

        connectionSetting =
            model.connectionSetting
    in
    case msg of
        OnClickLogin ->
            ( model
            , openConnection <| encodeConnectionSetting connectionSetting
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
                | connectionSetting =
                    { connectionSetting
                        | system = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionName s ->
            ( { model
                | connectionSetting =
                    { connectionSetting
                        | name = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionHostname s ->
            ( { model
                | connectionSetting =
                    { connectionSetting
                        | hostname = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionPort s ->
            ( { model
                | connectionSetting =
                    { connectionSetting
                        | portStr = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionUsername s ->
            ( { model
                | connectionSetting =
                    { connectionSetting
                        | username = s
                    }
              }
            , Cmd.none
            )

        OnChangeConnectionPassword s ->
            ( { model
                | connectionSetting =
                    { connectionSetting
                        | password = s
                    }
              }
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view model =
    div []
        [ viewHeader
        , viewConnections model
        , viewNewConnectionModal model
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
viewConnections _ =
    section [ class "section" ]
        [ div [ class "container" ]
            [ viewConnectionsHeader
            , viewConnectionCards
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


viewConnectionCards : Html Msg
viewConnectionCards =
    div [ class "columns is-multiline" ]
        (List.repeat 7 dummyCard)


dummyCard : Html Msg
dummyCard =
    viewConnectionCard "MySQL" "127.0.0.1:3306" "root"


viewConnectionCard : String -> String -> String -> Html Msg
viewConnectionCard system host user =
    div [ class "column is-one-third" ]
        [ div [ class "card" ]
            [ div [ class "card-content" ]
                [ div [ class "content is-small" ]
                    [ p [] [ text system ]
                    , p [] [ text host ]
                    , p [] [ text user ]
                    ]
                ]
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
                    [ onClick OnClickLogin
                    , class "button is-primary"
                    , disabled <| not <| validConnectionSetting model.connectionSetting
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
            model.connectionSetting
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
