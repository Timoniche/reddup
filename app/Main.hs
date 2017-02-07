{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Text hiding (empty)
import System.Directory
import Prelude hiding (FilePath, concat, empty)
import Turtle
import Git

data Trackable
  = GitRepo Turtle.FilePath
  | InboxDir Turtle.FilePath
  deriving (Show)

directoriesConfig :: Shell Trackable
directoriesConfig = do
  let
    gitRepos = [ "~/EF"
               , "~/Reference"
               , "~/Projects/*"
               ]
    inboxDirs = [ "~/Inbox",
                  "~/Desktop" ]

    in do
      gitDirectoriesConfig gitRepos
        <|> inboxDirectoriesConfig inboxDirs

gitDirectoriesConfig :: [Text] -> Shell Trackable
gitDirectoriesConfig dirs = do
  repoDir <- select dirs
  path <- expandGlob repoDir
  return $ (GitRepo . fromText . lineToText $ path)

inboxDirectoriesConfig :: [Text] -> Shell Trackable
inboxDirectoriesConfig dirs = do
  repoDir <- select dirs
  path <- expandGlob repoDir
  return $ (InboxDir . fromText . lineToText $ path)

expandGlob :: Text -> Shell Line
expandGlob x =
  inshell (concat ["for f in ", x, "; do echo $f; done"] ) Turtle.empty

handleTrackable :: Trackable -> Shell ()
handleTrackable (GitRepo dir) = do
  liftIO $ putStrLn $ "checking " ++ show dir
  cd dir
  dirExists <- testdir ".git"
  if dirExists then
    liftIO checkGitStatus
  else
    liftIO $ putStrLn $ "ERROR IS NOT GIT REPO"
  return ()

handleTrackable (InboxDir dir) = do
  liftIO $ putStrLn $ "checking " ++ show dir
  cd dir
  let status = ls "."
  view status
  return ()

checkGitStatus :: IO ()
checkGitStatus = do
  let status = gitStatus
  view status

main :: IO ()
main = sh $ do
  trackable <- directoriesConfig
  handleTrackable trackable
