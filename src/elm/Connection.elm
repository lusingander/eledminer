module Connection exposing
    ( Connection(..)
    , ConnectionFields
    , DefaultConnectionSetting
    , SqliteConnectionSetting
    , connectionDecoder
    , connectionsDecoder
    , defaultConnectionSettingDecoder
    , emptyConnection
    , encodeConnection
    , id
    , initConnectionFields
    , setPassword
    , sqliteConnectionSettingDecoder
    , system
    , toConnection
    , toConnectionFields
    )

import Json.Decode as JD
import Json.Encode as JE


type alias ConnectionFields =
    { id : String
    , system : String
    , name : String
    , hostname : String
    , portStr : String
    , username : String
    , password : String
    , savePassword : Maybe Bool
    , filepath : String
    }


initConnectionFields : ConnectionFields
initConnectionFields =
    { id = ""
    , system = "server"
    , name = ""
    , hostname = ""
    , portStr = ""
    , username = ""
    , password = ""
    , filepath = ""
    , savePassword = Just True
    }


toConnectionFields : Connection -> ConnectionFields
toConnectionFields c =
    case c of
        DefaultConnection s ->
            { id = s.id
            , system = s.system
            , name = s.name
            , hostname = s.hostname
            , portStr = s.portStr
            , username = s.username
            , password = s.password
            , savePassword = Just s.savePassword
            , filepath = ""
            }

        SqliteConnection s ->
            { id = s.id
            , system = s.system
            , name = s.name
            , hostname = ""
            , portStr = ""
            , username = ""
            , password = ""
            , savePassword = Nothing
            , filepath = s.filepath
            }


toConnection : ConnectionFields -> Connection
toConnection c =
    if c.system == "sqlite" || c.system == "sqlite2" then
        SqliteConnection
            { id = c.id
            , system = c.system
            , name = c.name
            , filepath = c.filepath
            }

    else
        DefaultConnection
            { id = c.id
            , system = c.system
            , name = c.name
            , hostname = c.hostname
            , portStr = c.portStr
            , username = c.username
            , password = c.password
            , savePassword = c.savePassword |> Maybe.withDefault True
            }


type Connection
    = DefaultConnection DefaultConnectionSetting
    | SqliteConnection SqliteConnectionSetting


emptyConnection : Connection
emptyConnection =
    DefaultConnection
        { id = ""
        , system = "server"
        , name = ""
        , hostname = ""
        , portStr = ""
        , username = ""
        , password = ""
        , savePassword = True
        }


id : Connection -> String
id c =
    case c of
        DefaultConnection s ->
            s.id

        SqliteConnection s ->
            s.id


system : Connection -> String
system c =
    case c of
        DefaultConnection s ->
            s.system

        SqliteConnection s ->
            s.system


setPassword : String -> Connection -> Connection
setPassword password conn =
    case conn of
        DefaultConnection s ->
            DefaultConnection
                { s
                    | password = password
                    , savePassword = True
                }

        _ ->
            conn


connectionsDecoder : JD.Decoder (List Connection)
connectionsDecoder =
    JD.list connectionDecoder


connectionDecoder : JD.Decoder Connection
connectionDecoder =
    JD.oneOf
        [ JD.map DefaultConnection defaultConnectionSettingDecoder
        , JD.map SqliteConnection sqliteConnectionSettingDecoder
        ]


encodeConnection : Connection -> JE.Value
encodeConnection c =
    case c of
        DefaultConnection s ->
            encodeDefaultConnection s

        SqliteConnection s ->
            encodeSqliteConnection s


type alias DefaultConnectionSetting =
    { id : String
    , system : String
    , name : String
    , hostname : String
    , portStr : String
    , username : String
    , password : String
    , savePassword : Bool
    }


defaultConnectionSettingDecoder : JD.Decoder DefaultConnectionSetting
defaultConnectionSettingDecoder =
    JD.map8 DefaultConnectionSetting
        (JD.field "id" JD.string)
        (JD.field "driver" JD.string)
        (JD.field "name" JD.string)
        (JD.field "hostname" JD.string)
        (JD.field "port" JD.string)
        (JD.field "username" JD.string)
        (JD.field "password" JD.string)
        (JD.field "savePassword" JD.bool)


encodeDefaultConnection : DefaultConnectionSetting -> JE.Value
encodeDefaultConnection c =
    let
        password =
            if c.savePassword then
                c.password

            else
                ""
    in
    JE.object
        [ ( "type", JE.string "default" )
        , ( "id", JE.string c.id )
        , ( "driver", JE.string c.system )
        , ( "name", JE.string c.name )
        , ( "hostname", JE.string c.hostname )
        , ( "port", JE.string c.portStr )
        , ( "username", JE.string c.username )
        , ( "password", JE.string password )
        , ( "savePassword", JE.bool c.savePassword )
        ]


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


encodeSqliteConnection : SqliteConnectionSetting -> JE.Value
encodeSqliteConnection c =
    JE.object
        [ ( "type", JE.string "sqlite" )
        , ( "id", JE.string c.id )
        , ( "driver", JE.string c.system )
        , ( "name", JE.string c.name )
        , ( "filepath", JE.string c.filepath )
        ]
