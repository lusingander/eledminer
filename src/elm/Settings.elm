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


port verifyPhpExecutablePath : JE.Value -> Cmd msg


port loadSettings : (JD.Value -> msg) -> Sub msg


port openPhpExecutablePathFileDialogSuccess : (JD.Value -> msg) -> Sub msg


port verifyPhpExecutablePathSuccess : (JD.Value -> msg) -> Sub msg


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
    , infoModalOpen : Bool
    , lastInfoMessage : String
    , errorModalOpen : Bool
    , lastErrorMessage : String
    , notificationVisible : Bool
    }


initUIStatus : UIStatus
initUIStatus =
    { confirmModalOpen = False
    , infoModalOpen = False
    , lastInfoMessage = ""
    , errorModalOpen = False
    , lastErrorMessage = ""
    , notificationVisible = False
    }


type Msg
    = Save
    | Cancel
    | ConfirmRestart
    | ConfirmPostpone
    | ConfirmCancel
    | LoadSettings (Result JD.Error UserSettings)
    | OnInputPhp String
    | VerifyPhpExecutablePath String
    | VerifyPhpExecutablePathSuccess (Result JD.Error Bool)
    | OnInputPort String
    | OnChangeTheme String
    | OpenPhpExecutablePathFileDialog
    | OpenPhpExecutablePathFileDialogSuccess (Result JD.Error String)
    | HideNotification
    | CloseInfoModal
    | CloseErrorModal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        settings =
            .settings model

        validStatus =
            .validStatus model
    in
    case msg of
        Save ->
            ( showConfirmModal model
            , Cmd.none
            )

        Cancel ->
            ( model
            , cancel ()
            )

        ConfirmRestart ->
            ( closeConfirmModal model
            , restart <| encodeUserSettings <| .settings model
            )

        ConfirmPostpone ->
            ( showNotification <| closeConfirmModal model
            , Cmd.batch
                [ postpone <| encodeUserSettings <| .settings model
                , hideNotificationAfterWait
                ]
            )

        ConfirmCancel ->
            ( closeConfirmModal model
            , Cmd.none
            )

        LoadSettings (Ok s) ->
            ( { model
                | settings = s
              }
            , Cmd.none
            )

        LoadSettings (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        OnInputPhp s ->
            ( { model
                | settings =
                    { settings
                        | phpExecutablePath = s
                    }
              }
            , Cmd.none
            )

        VerifyPhpExecutablePath s ->
            ( model
            , verifyPhpExecutablePath <| JE.string s
            )

        VerifyPhpExecutablePathSuccess (Ok success) ->
            if success then
                ( showInfoModal "The given PHP executable path is valid. The server can be started." model
                , Cmd.none
                )

            else
                ( showErrorModal "The given PHP executable path is invalid. The server cannot be started." model
                , Cmd.none
                )

        VerifyPhpExecutablePathSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        OnInputPort s ->
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
            ( { model
                | settings =
                    { settings
                        | phpExecutablePath = path
                    }
              }
            , Cmd.none
            )

        OpenPhpExecutablePathFileDialogSuccess (Err e) ->
            ( showErrorModal (JD.errorToString e) model
            , Cmd.none
            )

        OnChangeTheme s ->
            ( { model
                | settings =
                    { settings
                        | theme = s
                    }
              }
            , Cmd.none
            )

        HideNotification ->
            ( hideNotification model
            , Cmd.none
            )

        CloseInfoModal ->
            ( closeInfoModal model
            , Cmd.none
            )

        CloseErrorModal ->
            ( closeErrorModal model
            , Cmd.none
            )


showConfirmModal : Model -> Model
showConfirmModal =
    updateConfirmModalOpenStatus True


closeConfirmModal : Model -> Model
closeConfirmModal =
    updateConfirmModalOpenStatus False


updateConfirmModalOpenStatus : Bool -> Model -> Model
updateConfirmModalOpenStatus open model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | confirmModalOpen = open
            }
    }


showNotification : Model -> Model
showNotification =
    updateNotificationVisibleStatus True


hideNotification : Model -> Model
hideNotification =
    updateNotificationVisibleStatus False


updateNotificationVisibleStatus : Bool -> Model -> Model
updateNotificationVisibleStatus visible model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | notificationVisible = visible
            }
    }


showInfoModal : String -> Model -> Model
showInfoModal message =
    updateInfoModalOpenStatus True >> updateInfoModalLastMessage message


updateInfoModalLastMessage : String -> Model -> Model
updateInfoModalLastMessage message model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | lastInfoMessage = message
            }
    }


closeInfoModal : Model -> Model
closeInfoModal =
    updateInfoModalOpenStatus False


updateInfoModalOpenStatus : Bool -> Model -> Model
updateInfoModalOpenStatus open model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | infoModalOpen = open
            }
    }


showErrorModal : String -> Model -> Model
showErrorModal message =
    updateErrorModalOpenStatus True >> updateErrorModalLastMessage message


updateErrorModalLastMessage : String -> Model -> Model
updateErrorModalLastMessage message model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | lastErrorMessage = message
            }
    }


closeErrorModal : Model -> Model
closeErrorModal =
    updateErrorModalOpenStatus False


updateErrorModalOpenStatus : Bool -> Model -> Model
updateErrorModalOpenStatus open model =
    let
        oldUIStatus =
            model.uiStatus
    in
    { model
        | uiStatus =
            { oldUIStatus
                | errorModalOpen = open
            }
    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ loadSettings (JD.decodeValue userSettingsDecoder)
            |> Sub.map LoadSettings
        , openPhpExecutablePathFileDialogSuccess (JD.decodeValue JD.string)
            |> Sub.map OpenPhpExecutablePathFileDialogSuccess
        , verifyPhpExecutablePathSuccess (JD.decodeValue JD.bool)
            |> Sub.map VerifyPhpExecutablePathSuccess
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
        [ viewInfoModal model
        , viewErrorModal model
        , viewHeader
        , viewGeneralSection model
        , viewAppearanceSection settings
        , viewButtons model
        , viewSaveConfirmModal status
        , viewSuccessNotification status
        ]


viewInfoModal : Model -> Html Msg
viewInfoModal model =
    div [ class "modal", classIsActive <| model.uiStatus.infoModalOpen ]
        [ div [ class "modal-background", onClick CloseInfoModal ] []
        , div [ class "modal-content" ]
            [ article [ class "message is-info" ]
                [ div [ class "message-header" ]
                    [ p [] [ text "Info" ]
                    , button [ onClick CloseInfoModal, class "delete" ] []
                    ]
                , div [ class "message-body" ]
                    [ text model.uiStatus.lastInfoMessage ]
                ]
            ]
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
                , div [ class "column" ]
                    [ div
                        [ class "control", onClick <| VerifyPhpExecutablePath model.settings.phpExecutablePath ]
                        [ a [ class "button is-warning is-light is-rounded is-small" ] [ text "Verify Path" ]
                        ]
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
    div [ class "field" ]
        [ div [ class "field-body" ]
            [ div [ class "field has-addons" ]
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
            ]
        , p [ class "help" ]
            [ text "The path to PHP executable. If blank, it will be found from the PATH."
            ]
        ]


viewPortInput : Model -> Html Msg
viewPortInput model =
    div [ class "field" ]
        [ div [ class "control" ]
            [ input
                [ class "input is-small"
                , classInvalidStatus <| model.validStatus.portNumber
                , type_ "number"
                , placeholder "8000"
                , value <| model.settings.portNumber
                , onInput OnInputPort
                ]
                []
            ]
        , p [ class "help" ]
            [ text "The port to run the PHP server."
            ]
        ]


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
