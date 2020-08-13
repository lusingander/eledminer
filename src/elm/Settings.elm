port module Settings exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import Json.Encode as JE
import Process
import Task


port documentLoaded : () -> Cmd msg


port cancel : () -> Cmd msg


port restart : JE.Value -> Cmd msg


port postpone : JE.Value -> Cmd msg


port loadSettings : (JD.Value -> msg) -> Sub msg


port settingsSaveSuccess : (() -> msg) -> Sub msg


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
    , uiStatus = initUIStatus
    }


type alias UserSettings =
    { portNumber : Int
    , theme : String
    }


initUserSettings : UserSettings
initUserSettings =
    { portNumber = 0
    , theme = ""
    }


userSettingsDecoder : JD.Decoder UserSettings
userSettingsDecoder =
    JD.map2 UserSettings
        (JD.field "port" JD.int)
        (JD.field "theme" JD.string)


encodeUserSettings : UserSettings -> JE.Value
encodeUserSettings s =
    JE.object
        [ ( "port", JE.int <| .portNumber s )
        , ( "theme", JE.string <| .theme s )
        ]


type alias UIStatus =
    { confirmModalOpen : Bool
    , notificationVisible : Bool
    }


initUIStatus : UIStatus
initUIStatus =
    { confirmModalOpen = False
    , notificationVisible = False
    }


type Msg
    = Save
    | Cancel
    | ConfirmRestart
    | ConfirmPostpone
    | LoadSettings (Result JD.Error UserSettings)
    | SettingsSaveSuccess ()
    | OnInputPort String
    | OnChangeTheme String
    | HideNotification


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

        LoadSettings (Ok s) ->
            ( { model
                | settings = s
              }
            , Cmd.none
            )

        LoadSettings (Err _) ->
            -- handle error
            ( model
            , Cmd.none
            )

        SettingsSaveSuccess _ ->
            ( model
            , Cmd.none
            )

        OnInputPort s ->
            let
                settings =
                    .settings model
            in
            ( { model
                | settings =
                    { settings
                        | portNumber = s |> String.toInt |> Maybe.withDefault 0
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ loadSettings (JD.decodeValue userSettingsDecoder)
            |> Sub.map LoadSettings
        , settingsSaveSuccess SettingsSaveSuccess
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
        [ viewHeader
        , viewGeneralSection settings
        , viewAppearanceSection settings
        , viewButtons
        , viewSaveConfirmModal status
        , viewSuccessNotification status
        ]


viewHeader : Html Msg
viewHeader =
    header [ class "hero is-light" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ h1 [ class "title is-2" ]
                    [ text "Settings" ]
                ]
            ]
        ]


viewGeneralSection : UserSettings -> Html Msg
viewGeneralSection s =
    section [ class "section" ]
        [ div [ class "container" ]
            [ h2 [ class "title is-3" ]
                [ text "General" ]
            , h3 [ class "title is-4" ]
                [ text "Port" ]
            , div [ class "columns" ]
                [ div [ class "column is-one-quarter" ]
                    [ viewPortInput s
                    ]
                ]
            ]
        ]


viewPortInput : UserSettings -> Html Msg
viewPortInput s =
    input
        [ class "input"
        , type_ "number"
        , placeholder "8000"
        , value <| portStr s
        , onInput OnInputPort
        ]
        []


portStr : UserSettings -> String
portStr =
    .portNumber >> String.fromInt


viewAppearanceSection : UserSettings -> Html Msg
viewAppearanceSection s =
    section [ class "section" ]
        [ div [ class "container" ]
            [ h2 [ class "title is-3" ]
                [ text "Appearance" ]
            , h3 [ class "title is-4" ]
                [ text "Theme" ]
            , div []
                [ div [ class "select" ]
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
    , "kahi2"
    ]


viewButtons : Html Msg
viewButtons =
    div [ class "buttons are-medium" ]
        [ button [ onClick Save, class "button is-success is-outlined" ]
            [ span [] [ text "Save" ] ]
        , button [ onClick Cancel, class "button is-light" ]
            [ span [] [ text "Cancel" ] ]
        ]


viewSaveConfirmModal : UIStatus -> Html Msg
viewSaveConfirmModal s =
    div [ class "modal", classIsActive <| .confirmModalOpen s ]
        [ div [ class "modal-background" ] []
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
    div [ id "save-success-notification", class "notification is-success", classNotificationVisible <| .notificationVisible s ]
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
