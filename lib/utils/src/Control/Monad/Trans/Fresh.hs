{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, UndecidableInstances #-}  -- require for MonadError
-- |
-- Copyright   : (c) 2010 Simon Meier
-- License     : GPL v3 (see LICENSE)
-- 
-- Maintainer  : Simon Meier <iridcode@gmail.com>
-- Portability : GHC only
--
-- A monad transformer for passing a fresh name supply through a computation.
-- This is just a newtype wrapper around the 'StateT' monad transformer.
--
-- Modeled after the mtl-2.0 library.
--
module Control.Monad.Trans.Fresh (

  -- * The Fresh monad
    Fresh
  , runFresh
  , evalFresh
  , execFresh

  -- * The FreshT monad transformer
  , FreshT(..)
  , freshT
  , runFreshT
  , evalFreshT
  , execFreshT

  -- * Fresh name generation
  , FreshState
  , nothingUsed
  , freshIdent

  ) where

import Control.Basics
import Control.Monad.Identity
import Control.Monad.State.Strict
import Control.Monad.Error
import Control.Monad.Reader

------------------------------------------------------------------------------
-- FreshT monad transformer
------------------------------------------------------------------------------

-- | The state of the name supply: the last used sequence number of every name.
type FreshState = Int

-- | A computation that can generate fresh variables from name hints.
newtype FreshT m a = FreshT { unFreshT :: StateT FreshState m a }
    deriving( Functor, Applicative, Alternative, Monad, MonadPlus, MonadTrans )

-- | Construct a 'FreshT' action from a 'FreshState' modification.
freshT :: (FreshState -> m (a, FreshState)) -> FreshT m a
freshT = FreshT . StateT

-- | The empty fresh state.
nothingUsed :: FreshState
nothingUsed = 0

-- | Run a computation with a fresh name supply.
runFreshT :: FreshT m a -> FreshState -> m (a, FreshState)
runFreshT (FreshT m) used = runStateT m used

-- | Evaluate a computation with a fresh name supply.
evalFreshT :: Monad m => FreshT m a -> FreshState -> m a
evalFreshT (FreshT m) used = evalStateT m used

-- | Execute a computation with a fresh name supply.
execFreshT :: Monad m => FreshT m a -> FreshState -> m FreshState
execFreshT (FreshT m) used = execStateT m used

-- | Get a fresh identifier.
freshIdent :: Monad m 
           => String        -- ^ Desired name.
           -> FreshT m Int  -- ^ Fresh identifier for this name.
freshIdent _ = do
    i <- FreshT get
    FreshT $ put $ succ i
    return i

-- Instances
------------

instance MonadError e m => MonadError e (FreshT m) where
    throwError     = lift . throwError
    catchError m h = FreshT $ catchError (unFreshT m) (unFreshT . h)

instance MonadReader r m => MonadReader r (FreshT m) where
    ask       = lift ask
    local f m = FreshT $ local f $ unFreshT m

------------------------------------------------------------------------------
-- Fresh monad
------------------------------------------------------------------------------

type Fresh = FreshT Identity

-- | Run a computation with a fresh name supply.
runFresh :: Fresh a -> FreshState -> (a, FreshState)
runFresh (FreshT m) used = runState m used

-- | Evaluate a computation with a fresh name supply.
evalFresh :: Fresh a -> FreshState -> a
evalFresh (FreshT m) used = evalState m used

-- | Execute a computation with a fresh name supply.
execFresh :: Fresh a -> FreshState -> FreshState
execFresh (FreshT m) used = execState m used
