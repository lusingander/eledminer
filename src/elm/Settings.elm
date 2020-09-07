port module Settings exposing (main)

import Browser
import Html exposing (Html, a, article, button, div, footer, h1, h2, h3, header, i, input, option, p, section, select, span, text)
import Html.Attributes exposing (class, disabled, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import Json.Encode as JE
import Process
import Task


port documentLoaded : () -> Cmd msg


port cancel : () -> Cmd msg


port openPhpExecutablePathFileDialog : () -> Cmd msg


port restart : JE.Value -> Cmd msg


port postpone : JE.Value -> Cmd msg


port loadSettings : (JD.Value -> msg) -> Sub msg


port openPhpExecutablePathFileDialogSuccess : (JD.Value -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { settings : UserSettings
    , validStatus : ValidStatus
    , uiStatus : UIStatus
    , errorStatus : ErrorStatus
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( initModel
    , documentLoaded ()
    )


initModel : Model
initModel =
    { settings = initUserSettings
    , validStatus = initValidStatus
    , uiStatus = initUIStatus
    , errorStatus = initErrorStatus
    }


type alias UserSettings =
    { phpExecutablePath : String
    , portNumber : String
    , theme : String
    }


initUserSettings : UserSettings
initUserSettings =
    { phpExecutablePath = ""
    , portNumber = ""
    , theme = ""
    }


userSettingsDecoder : JD.Decoder UserSettings
userSettingsDecoder =
    JD.map3 UserSettings
        (JD.field "php" JD.string)
        (JD.field "port" JD.int |> JD.map String.fromInt)
        (JD.field "theme" JD.string)


encodeUserSettings : UserSettings -> JE.Value
encodeUserSettings s =
    JE.object
        [ ( "php", JE.string <| .phpExecutablePath s )
        , ( "port", JE.int <| portNumberAsInt s )
        , ( "theme", JE.string <| .theme s )
        ]


portNumberAsInt : UserSettings -> Int
portNumberAsInt =
    .portNumber >> toIntOrZero


toIntOrZero : String -> Int
toIntOrZero =
    String.toInt >> Maybe.withDefault 0


type alias ValidStatus =
    { portNumber : Bool
    }


initValidStatus : ValidStatus
initValidStatus =
    { portNumber = True
    }


validPortNumber : String -> Bool
validPortNumber =
    toIntOrZero >> (<) 0


canSave : ValidStatus -> Bool
canSave s =
    s.portNumber


type alias UIStatus =
    { confirmModalOpen : Bool
    , notificationVisible : Bool
    }


initUIStatus : UIStatus
initUIStatus =
    { confirmModalOpen = False
    , notificationVisible = False
    }


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
    = Save
    | Cancel
    | ConfirmRestart
    | ConfirmPostpone
    | ConfirmCancel
    | LoadSettings (Result JD.Error UserSettings)
    | OnInputPhp String
    | OnInputPort String
    | OnChangeTheme String
    | OpenPhpExecutablePathFileDialog
    | OpenPhpExecutablePathFileDialogSuccess (Result JD.Error String)
    | HideNotification
    | CloseErrorModal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Save ->
            let
                status =
                    .uiStatus model
            in
            ( { model
                | uiStatus =
                    { status
                        | confirmModalOpen = True
                    }
              }
            , Cmd.none
            )

        Cancel ->
            ( model
            , cancel ()
            )

        ConfirmRestart ->
            let
                status =
                    .uiStatus model
            in
            ( { model
                | uiStatus =
                    { status
                        | confirmModalOpen = False
                    }
              }
            , restart <| encodeUserSettings <| .settings model
            )

        ConfirmPostpone ->
            let
                status =
                    .uiStatus model
            in
            ( { model
                | uiStatus =
                    { status
                        | confirmModalOpen = False
                        , notificationVisible = True
                    }
              }
            , Cmd.batch
                [ postpone <| encodeUserSettings <| .settings model
                , hideNotificationAfterWait
                ]
            )

        ConfirmCancel ->
            let
                status =
                    .uiStatus model
            in
            ( { model
                | uiStatus =
                    { status
                        | confirmModalOpen = False
                    }
              }
            , Cmd.none
            )

        LoadSettings (Ok s) ->
            ( { model
                | settings = s
              }
            , Cmd.none
            )

        LoadSettings (Err e) ->
            ( { model
                | errorStatus =
                    { errorModalOpen = True
                    , lastErrorMessage = JD.errorToString e
                    }
              }
            , Cmd.none
            )

        OnInputPhp s ->
            let
                settings =
                    .settings model
            in
            ( { model
                | settings =
                    { settings
                        | phpExecutablePath = s
                    }
              }
            , Cmd.none
            )

        OnInputPort s ->
            let
                settings =
                    .settings model

                validStatus =
                    .validStatus model
            in
            ( { model
                | settings =
                    { settings
                        | portNumber = s
                    }
                , validStatus =
                    { validStatus
                        | portNumber = validPortNumber s
                    }
              }
            , Cmd.none
            )

        OpenPhpExecutablePathFileDialog ->
            ( model
            , openPhpExecutablePathFileDialog ()
            )

        OpenPhpExecutablePathFileDialogSuccess (Ok path) ->
            let
                settings =
                    .settings model
            in
            ( { model
                | settings =
                    { settings
                        | phpExecutablePath = path
                    }
              }
            , Cmd.none
            )

        OpenPhpExecutablePathFileDialogSuccess (Err e) ->
            ( { model
                | errorStatus =
                    { errorModalOpen = True
                    , lastErrorMessage = JD.errorToString e
                    }
              }
            , Cmd.none
            )

        OnChangeTheme s ->
            let
                settings =
                    .settings model
            in
            ( { model
                | settings =
                    { settings
                        | theme = s
                    }
              }
            , Cmd.none
            )

        HideNotification ->
            let
                status =
                    .uiStatus model
            in
            ( { model
                | uiStatus =
                    { status
                        | notificationVisible = False
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
        [ loadSettings (JD.decodeValue userSettingsDecoder)
            |> Sub.map LoadSettings
        , openPhpExecutablePathFileDialogSuccess (JD.decodeValue JD.string)
            |> Sub.map OpenPhpExecutablePathFileDialogSuccess
        ]


view : Model -> Html Msg
view model =
    let
        settings =
            .settings model

        status =
            .uiStatus model
    in
    div []
        [ viewErrorModal model
        , viewHeader
        , viewGeneralSection model
        , viewAppearanceSection settings
        , viewButtons model
        , viewSaveConfirmModal status
        , viewSuccessNotification status
        ]


viewErrorModal : Model -> Html Msg
viewErrorModal model =
    div [ class "modal", classIsActive <| model.errorStatus.errorModalOpen ]
        [ div [ class "modal-background", onClick CloseErrorModal ] []
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
                    [ text "Settings" ]
                ]
            ]
        ]


viewGeneralSection : Model -> Html Msg
viewGeneralSection model =
    section [ class "section" ]
        [ div [ class "container" ]
            [ h2 [ class "title is-4" ]
                [ text "General" ]
            , h3 [ class "title is-5" ]
                [ text "PHP Executable Path" ]
            , div [ class "columns" ]
                [ div [ class "column is-half" ]
                    [ viewPhpExecutablePath model
                    ]
                ]
            , h3 [ class "title is-5" ]
                [ text "PHP Server Port" ]
            , div [ class "columns" ]
                [ div [ class "column is-one-quarter" ]
                    [ viewPortInput model
                    ]
                ]
            ]
        ]


viewPhpExecutablePath : Model -> Html Msg
viewPhpExecutablePath model =
    div [ class "field has-addons" ]
        [ div [ class "control is-expanded" ]
            [ input
                [ class "input is-small"
                , type_ "text"
                , value <| model.settings.phpExecutablePath
                , onInput OnInputPhp
                ]
                []
            ]
        , div [ class "control", onClick OpenPhpExecutablePathFileDialog ]
            [ a [ class "button is-link is-small" ]
                [ span [] [ i [ class "fas fa-folder-open" ] [] ]
                ]
            ]
        ]


viewPortInput : Model -> Html Msg
viewPortInput model =
    input
        [ class "input is-small"
        , classInvalidStatus <| model.validStatus.portNumber
        , type_ "number"
        , placeholder "8000"
        , value <| model.settings.portNumber
        , onInput OnInputPort
        ]
        []


classInvalidStatus : Bool -> Html.Attribute Msg
classInvalidStatus valid =
    if valid then
        class ""

    else
        class "is-danger"


viewAppearanceSection : UserSettings -> Html Msg
viewAppearanceSection s =
    section [ class "section" ]
        [ div [ class "container" ]
            [ h2 [ class "title is-4" ]
                [ text "Appearance" ]
            , h3 [ class "title is-5" ]
                [ text "Theme" ]
            , div []
                [ div [ class "select is-small" ]
                    [ viewThemeSelect s
                    ]
                ]
            ]
        ]


viewThemeSelect : UserSettings -> Html Msg
viewThemeSelect s =
    let
        handler selected =
            OnChangeTheme selected
    in
    select
        [ value (.theme s)
        , onChange handler
        ]
        themeNameOptions


onChange : (String -> msg) -> Html.Attribute msg
onChange handler =
    Html.Events.on "change" (JD.map handler Html.Events.targetValue)


themeNameOptions : List (Html Msg)
themeNameOptions =
    List.map (\n -> option [] [ text n ]) themeNames


themeNames : List String
themeNames =
    [ "default"
    , "hever"
    , "nette"
    , "brade"
    , "ng9"
    , "pepa-linha"
    , "lucas-sandery"
    , "pappu687"
    , "mvt"
    , "rmsoft"
    , "rmsoft blue"
    , "pepa-linha-dark"
    , "mancave"
    , "galkaev"
    , "hydra"
    , "arcs-material"
    , "price"
    , "flat"
    , "haeckel"
    , "pokorny"
    , "paranoiq"
    , "bueltge"
    , "esterka"
    , "nicu"
    , "arcs-"
    , "konya"
    , "pilot"
    , "kahi"
    , "cvicebni-ubor"
    , "jukin"
    ]


viewButtons : Model -> Html Msg
viewButtons model =
    div [ class "buttons are-medium" ]
        [ button [ onClick Save, class "button is-success is-outlined", disabled <| not <| canSave model.validStatus ]
            [ span [] [ text "Save" ] ]
        , button [ onClick Cancel, class "button is-light" ]
            [ span [] [ text "Cancel" ] ]
        ]


viewSaveConfirmModal : UIStatus -> Html Msg
viewSaveConfirmModal s =
    div [ class "modal", classIsActive <| .confirmModalOpen s ]
        [ div [ class "modal-background", onClick ConfirmCancel ] []
        , div [ class "modal-content" ]
            [ header [ class "modal-card-head" ]
                [ p [ class "modal-card-title" ] [ text "Confirm" ] ]
            , section [ class "modal-card-body" ]
                [ div [] [ text "Restart application to apply settings changes." ] ]
            , footer [ class "modal-card-foot" ]
                [ button [ onClick ConfirmRestart, class "button is-danger" ] [ text "Restart now" ]
                , button [ onClick ConfirmPostpone, class "button is-light" ] [ text "Postpone" ]
                ]
            ]
        ]


classIsActive : Bool -> Html.Attribute Msg
classIsActive active =
    if active then
        class "is-active"

    else
        class ""


viewSuccessNotification : UIStatus -> Html Msg
viewSuccessNotification s =
    div [ class "notification is-success", classNotificationVisible <| .notificationVisible s ]
        [ span [] [ text "Settings were saved successfully" ] ]


classNotificationVisible : Bool -> Html.Attribute Msg
classNotificationVisible visible =
    if visible then
        class "notification-visible"

    else
        class ""


hideNotificationAfterWait : Cmd Msg
hideNotificationAfterWait =
    Process.sleep 3000
        |> Task.andThen (always <| Task.succeed HideNotification)
        |> Task.perform identity
