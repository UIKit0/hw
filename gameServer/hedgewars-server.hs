{-# LANGUAGE CPP, ScopedTypeVariables, OverloadedStrings #-}

module Main where

import Network.Socket
import Network.BSD
import Control.Concurrent.Chan
import qualified Control.Exception as E
import System.Log.Logger
-----------------------------------
import Opts
import CoreTypes
import ServerCore
#if defined(OFFICIAL_SERVER)
import ConfigFile
#endif

#if !defined(mingw32_HOST_OS)
import System.Posix
#endif


setupLoggers :: IO ()
setupLoggers = do
    updateGlobalLogger "Clients" (setLevel NOTICE)
    updateGlobalLogger "Core" (setLevel NOTICE)


server :: ServerInfo -> IO ()
server si = do
    proto <- getProtocolNumber "tcp"
    E.bracket
        (socket AF_INET Stream proto)
        sClose
        (\sock -> do
            setSocketOption sock ReuseAddr 1
            bindSocket sock (SockAddrInet (listenPort si) iNADDR_ANY)
            listen sock maxListenQueue
            startServer si{serverSocket = Just sock}
        )

handleRestart :: ShutdownException -> IO ()
handleRestart ShutdownException = do
    noticeM "Core" "Shutting down"
    return ()

main :: IO ()
main = withSocketsDo $ do
#if !defined(mingw32_HOST_OS)
    _ <- installHandler sigPIPE Ignore Nothing
    _ <- installHandler sigCHLD Ignore Nothing
#endif

    setupLoggers

    dbQueriesChan <- newChan
    coreChan' <- newChan
    serverInfo' <- getOpts $ newServerInfo coreChan' dbQueriesChan Nothing Nothing

#if defined(OFFICIAL_SERVER)
    si <- readServerConfig serverInfo'
#else
    let si = serverInfo'
#endif

    (server si) `E.catch` handleRestart
