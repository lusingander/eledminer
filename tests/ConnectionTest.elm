module ConnectionTest exposing (suite)

import Connection
import Expect
import Json.Decode as JD
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Connection module"
        [ describe "connection decoder"
            [ test "defaultConnectionSettingDecoder" <|
                \() ->
                    let
                        json =
                            """
                            {
                                "type": "default",
                                "id": "73ea006d-8627-4ff0-90a9-62f2119d642b",
                                "driver": "server",
                                "name": "test server",
                                "hostname": "127.0.0.1",
                                "port": "12345",
                                "username": "root",
                                "password": "P@ssw0rd"
                            }
                            """

                        expected =
                            Ok
                                { id = "73ea006d-8627-4ff0-90a9-62f2119d642b"
                                , system = "server"
                                , name = "test server"
                                , hostname = "127.0.0.1"
                                , portStr = "12345"
                                , username = "root"
                                , password = "P@ssw0rd"
                                }

                        actual =
                            JD.decodeString Connection.defaultConnectionSettingDecoder json
                    in
                    Expect.equal actual expected
            , test "sqliteConnectionSettingDecoder" <|
                \() ->
                    let
                        json =
                            """
                            {
                                "type": "sqlite",
                                "id": "73ea006d-8627-4ff0-90a9-62f2119d642b",
                                "driver": "sqlite",
                                "name": "test sqlite3 server",
                                "filepath": "/path/to/file/test.db"
                            }
                            """

                        expected =
                            Ok
                                { id = "73ea006d-8627-4ff0-90a9-62f2119d642b"
                                , system = "sqlite"
                                , name = "test sqlite3 server"
                                , filepath = "/path/to/file/test.db"
                                }

                        actual =
                            JD.decodeString Connection.sqliteConnectionSettingDecoder json
                    in
                    Expect.equal actual expected
            , test "connectionsDecoder" <|
                \() ->
                    let
                        json =
                            """
                            [
                            {
                                "type": "sqlite",
                                "id": "73ea006d-8627-4ff0-90a9-62f2119d642b",
                                "driver": "sqlite",
                                "name": "test sqlite3 server",
                                "filepath": "/path/to/file/test.db"
                            },
                            {
                                "type": "default",
                                "id": "73ea006d-8627-4ff0-90a9-62f2119d642b",
                                "driver": "server",
                                "name": "test server",
                                "hostname": "127.0.0.1",
                                "port": "12345",
                                "username": "root",
                                "password": "P@ssw0rd"
                            }
                            ]
                            """

                        expected =
                            Ok
                                [ Connection.SqliteConnection
                                    { id = "73ea006d-8627-4ff0-90a9-62f2119d642b"
                                    , system = "sqlite"
                                    , name = "test sqlite3 server"
                                    , filepath = "/path/to/file/test.db"
                                    }
                                , Connection.DefaultConnection
                                    { id = "73ea006d-8627-4ff0-90a9-62f2119d642b"
                                    , system = "server"
                                    , name = "test server"
                                    , hostname = "127.0.0.1"
                                    , portStr = "12345"
                                    , username = "root"
                                    , password = "P@ssw0rd"
                                    }
                                ]

                        actual =
                            JD.decodeString Connection.connectionsDecoder json
                    in
                    Expect.equal actual expected
            ]
        ]
