port module Menu exposing (main)

import Browser
import Html exposing (Html, div, i, span, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


port home : () -> Cmd msg


port settings : () -> Cmd msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    {}


init : () -> ( Model, Cmd msg )
init _ =
    ( initModel
    , Cmd.none
    )


initModel : Model
initModel =
    {}


type Msg
    = OnClickHome
    | OnClickSettings


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnClickHome ->
            ( model
            , home ()
            )

        OnClickSettings ->
            ( model
            , settings ()
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view _ =
    div [ class "menu-area" ]
        [ div [ onClick OnClickHome ]
            [ span [ class "icon btn-icon" ] [ i [ class "fas fa-home" ] [] ] ]
        , div [ onClick OnClickSettings ]
            [ span [ class "icon btn-icon btn-icon-bottom" ] [ i [ class "fas fa-cog" ] [] ] ]
        ]
