{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}

module Git where

import Data.Text (concat)
import Turtle
import Prelude hiding (FilePath, concat)
import qualified Control.Foldl as Fold

import GitParse

gitStatus :: Shell GitStatusType
gitStatus = do
  let statusStream = inshell "git status --porcelain" Turtle.empty
  fmap parseGitStatusLine statusStream

gitBranches :: Shell GitBranchType
gitBranches = do
  let branchStream = inshell "git branch" Turtle.empty
  fmap parseGitBranchLine branchStream

lengthOfOutput :: Shell Turtle.Line -> Shell Int
lengthOfOutput cmd = Turtle.fold cmd Fold.length

remoteBranchContainsBranch :: GitBranchType -> Shell Bool
remoteBranchContainsBranch (GitBranch name) = do
  let command = inshell (concat ["git branch -r --contains ", name]) Turtle.empty
  len <- lengthOfOutput command
  return $ len > 0

withoutRemote :: Shell GitBranchType -> GitBranchType -> Shell GitBranchType
withoutRemote accum next = do
  remoteFound <- remoteBranchContainsBranch next
  if remoteFound then
    accum
  else
    accum <|> return next

unpushedGitBranches :: Shell GitBranchType
unpushedGitBranches = join $ fold gitBranches $ Fold withoutRemote mzero id