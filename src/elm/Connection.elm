module Connection exposing
    ( Connection(..)
    , DefaultConnectionSetting
    , SqliteConnectionSetting
    , connectionDecoder
    , connectionsDecoder
    , defaultConnectionSettingDecoder
    , sqliteConnectionSettingDecoder
    )

import Json.Decode as JD


type Connection
    = DefaultConnection DefaultConnectionSetting
    | SqliteConnection SqliteConnectionSetting


connectionsDecoder : JD.Decoder (List Connection)
connectionsDecoder =
    JD.list connectionDecoder


connectionDecoder : JD.Decoder Connection
connectionDecoder =
    JD.oneOf
        [ JD.map DefaultConnection defaultConnectionSettingDecoder
        , JD.map SqliteConnection sqliteConnectionSettingDecoder
        ]


type alias DefaultConnectionSetting =
    { id : String
    , system : String
    , name : String
    , hostname : String
    , portStr : String
    , username : String
    , password : String
    }


defaultConnectionSettingDecoder : JD.Decoder DefaultConnectionSetting
defaultConnectionSettingDecoder =
    JD.map7 DefaultConnectionSetting
        (JD.field "id" JD.string)
        (JD.field "driver" JD.string)
        (JD.field "name" JD.string)
        (JD.field "hostname" JD.string)
        (JD.field "port" JD.string)
        (JD.field "username" JD.string)
        (JD.field "password" JD.string)


type alias SqliteConnectionSetting =
    { id : String
    , system : String
    , name : String
    , filepath : String
    }


sqliteConnectionSettingDecoder : JD.Decoder SqliteConnectionSetting
sqliteConnectionSettingDecoder =
    JD.map4 SqliteConnectionSetting
        (JD.field "id" JD.string)
        (JD.field "driver" JD.string)
        (JD.field "name" JD.string)
        (JD.field "filepath" JD.string)
