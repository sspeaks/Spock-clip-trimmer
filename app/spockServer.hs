{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Control.Monad.Trans   (MonadIO (liftIO))
import qualified Data.HashMap.Lazy     as HM
import           Data.IORef            (IORef, atomicModifyIORef', newIORef)
import           Data.Maybe            (fromJust, fromMaybe)
import qualified Data.Text             as T
import qualified Data.Text.Encoding    as T
import qualified Data.Text.IO          as TO
import           Data.Time.Clock.POSIX (getPOSIXTime)
import           Data.Traversable      (forM)
import           Network.HTTP.Types    (Status (statusCode, statusMessage))
import           System.Directory      (copyFile, removeFile)
import           System.EasyFile       (splitExtension)
import           System.IO             (stderr)
import           System.Process        (callProcess)
import           Web.Spock             (ActionCtxT,
                                        CookieEOL (CookieValidForSession, CookieValidForever),
                                        HasSpock (getState), SpockM,
                                        UploadedFile (uf_name, uf_tempLocation),
                                        clearAllSessions, files, html, params,
                                        post, root, runSpock, spock, text, var,
                                        (<//>))
import           Web.Spock.Config      (PoolOrConn (PCNoDatabase),
                                        SessionCfg (..), SpockCfg (..),
                                        defaultSessionHooks, defaultSpockCfg,
                                        newStmSessionStore)


myDefaultSessionCfg :: a -> IO (SessionCfg conn a st)
myDefaultSessionCfg emptySession = do
  store <- newStmSessionStore
  return SessionCfg { sc_cookieName           = ""
                    , sc_cookieEOL            = CookieValidForSession
                    , sc_sessionTTL           = 0
                    , sc_sessionIdEntropy     = 64
                    , sc_sessionExpandTTL     = False
                    , sc_emptySession         = emptySession
                    , sc_store                = store
                    , sc_housekeepingInterval = 60 * 10
                    , sc_hooks                = defaultSessionHooks
                    }


config sess conn st = do
  defSess <- myDefaultSessionCfg sess
  return SpockCfg { spc_initialState   = st
                  , spc_database       = conn
                  , spc_sessionCfg     = defSess
                  , spc_maxRequestSize = Just (2 * 1024 * 1024 * 1024)
                  , spc_logError       = TO.hPutStrLn stderr
                  , spc_errorHandler   = errorHandler
                  , spc_csrfProtection = False
                  , spc_csrfHeaderName = "X-Csrf-Token"
                  , spc_csrfPostName   = "__csrf_token"
                  }

errorHandler :: Status -> ActionCtxT () IO ()
errorHandler status = html $ errorTemplate status

-- Danger! This should better be done using combinators, but we do not
-- want Spock depending on a specific html combinator framework
errorTemplate :: Status -> T.Text
errorTemplate s =
  "<html><head>"
    <> "<title>"
    <> message
    <> "</title>"
    <> "</head>"
    <> "<body>"
    <> "<h1>"
    <> message
    <> "</h1>"
    <> "<a href='https://www.spock.li'>powered by Spock</a>"
    <> "</body>"
 where
  message = showT (statusCode s) <> " - " <> T.decodeUtf8 (statusMessage s)
  showT   = T.pack . show


data MySession = EmptySession
newtype MyAppState = DummyAppState ()

main :: IO ()
main = do
  spockCfg <- config EmptySession PCNoDatabase (DummyAppState ())
  runSpock 8080 (spock spockCfg app)

fftrim :: T.Text -> T.Text -> T.Text -> T.Text -> IO T.Text
fftrim start stop input outFileWantedName =
  let
    (fileHeader, _) = splitExtension (T.unpack input)
    (trimOutFileWant, _) = splitExtension (T.unpack outFileWantedName)
    timeMillis      = show . round <$> getPOSIXTime
    outFileName tm = if T.length (T.strip trimOutFileWant) == 0 then ("trimmed_" ++ fileHeader ++ "_" ++ tm ++ ".mp3") else trimOutFileWant ++ "_" ++ tm ++ ".mp3"
    startRay =
      if T.length (T.strip start) == 0 then [] else ["-ss", T.unpack start]
    stopRay =
      if T.length (T.strip stop) == 0 then [] else ["-to", T.unpack stop]
    resArray tm =
      (  (startRay ++ stopRay)
      ++ ["-i", T.unpack input, "-q:a", "0", "-map", "a","-af","dynaudnorm=f=50:g=15:m=20", outFileName tm]
      )
  in
    do
      tm <- timeMillis
      callProcess "ffmpeg" (resArray tm)
      return (T.pack (outFileName tm))


app :: SpockM () MySession MyAppState ()
app = do
  post "pogbot" $ do
    fs          <- files
    ps          <- params
    outFileName <-
      liftIO
        $ let (txt, f) = (head $ HM.toList fs)
          in
            do
              let fileName = uf_name f
              copyFile (uf_tempLocation f) ("./" ++ T.unpack fileName)
              removeFile (uf_tempLocation f)
              let startTimestamp = fromMaybe "" $ lookup "start" ps
              let stopTimestamp  = fromMaybe "" $ lookup "stop" ps
              let wantedOutFile = fromMaybe "" $ lookup "fileName" ps
              outFile <- fftrim startTimestamp stopTimestamp fileName wantedOutFile
              copyFile
                (T.unpack outFile)
                ("/home/sspeaks/pogbot/assets/audio/" ++ T.unpack outFile)
              removeFile (T.unpack fileName)
              removeFile (T.unpack outFile)
              return outFile
    clearAllSessions
    text "Okay"
