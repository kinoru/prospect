module ByteString
    ( readFile
    , writeFile
    , appendFile
    , withFile
    , module B
    , RawFilePath
    , putBuilder
    , toByteString
    ) where

import Prelude hiding (readFile, writeFile, appendFile)
import Control.Exception (bracket)
import System.IO (IOMode(..), Handle, hClose, stdout)
import Data.ByteString as B hiding (readFile, writeFile, appendFile)
import Data.ByteString.Builder as B
import Data.ByteString.Lazy as LB (toStrict)
import System.Posix.ByteString

defaultFlags :: OpenFileFlags
defaultFlags = OpenFileFlags
    { System.Posix.ByteString.append = False
    , exclusive = False
    , noctty = True
    , nonBlock = False
    , trunc = False
    }

appendFlags :: OpenFileFlags
appendFlags = defaultFlags { System.Posix.ByteString.append = True }

-- | Read an entire file at the 'RawFilePath' strictly into a 'ByteString'.
readFile :: RawFilePath -> IO ByteString
readFile path = withFile path ReadMode B.hGetContents

-- | Write a 'ByteString' to a file at the 'RawFilePath'.
writeFile :: RawFilePath -> ByteString -> IO ()
writeFile path content = withFile path WriteMode (`B.hPut` content)

appendFile :: RawFilePath -> ByteString -> IO ()
appendFile path content = withFile path AppendMode (`B.hPut` content)

withFile :: RawFilePath -> IOMode -> (Handle -> IO r) -> IO r
withFile path ioMode = bracket (open >>= fdToHandle) hClose
  where
    open = case ioMode of
        ReadMode -> openFd path ReadOnly Nothing defaultFlags
        WriteMode -> createFile path stdFileMode
        AppendMode -> openFd path WriteOnly (Just stdFileMode) appendFlags
        ReadWriteMode -> openFd path ReadWrite (Just stdFileMode) defaultFlags

putBuilder :: Builder -> IO ()
putBuilder = B.hPutBuilder stdout

toByteString :: Builder -> ByteString
toByteString = LB.toStrict . B.toLazyByteString

-- byteString :: String -> ByteString
-- byteString = toByteString . B.stringUtf8
