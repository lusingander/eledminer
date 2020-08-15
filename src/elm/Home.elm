port module Home exposing (main)

import Browser
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


port openConnection : () -> Cmd msg


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
    = OnClickLogin


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnClickLogin ->
            ( model
            , openConnection ()
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Html Msg
view _ =
    div []
        [ div [ onClick OnClickLogin ]
            [ button [] [ text "Login" ] ]
        ]
