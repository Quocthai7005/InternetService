{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (forM_)
import Data.Csv
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as BL
import Database.MySQL.Simple
import Database.MySQL.Simple.FromRow
import Database.MySQL.Simple.ToRow

-- Define the data structure
data Subscription = Subscription
  { customerID       :: Int
  , name             :: String
  , subscriptionType :: String
  , speedMbps        :: Int
  , price            :: Double
  , startDate        :: String
  , endDate          :: String
  , status           :: String
  , paymentMethod    :: String
  , contractLength   :: Int
  } deriving (Show)

-- Make Subscription an instance of FromRow and ToRow
instance FromRow Subscription where
  fromRow = Subscription <$> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field <*> field

instance ToRow Subscription where
  toRow (Subscription cid n st sp pr sd ed s pm cl) =
    toRow (cid, n, st, sp, pr, sd, ed, s, pm, cl)

-- Function to read CSV file and insert into MySQL database
importCSVAndInsert :: FilePath -> Connection -> IO ()
importCSVAndInsert filePath conn = do
  csvData <- BL.readFile filePath
  case decode NoHeader csvData of
    Left err -> putStrLn $ "Error parsing CSV: " ++ err
    Right subscriptions -> do
      forM_ subscriptions $ \sub -> do
        execute conn "INSERT INTO subscriptions (CustomerID, Name, SubscriptionType, SpeedMbps, Price, StartDate, EndDate, Status, PaymentMethod, ContractLength) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" sub
      putStrLn "Data inserted successfully!"

main :: IO ()
main = do
  -- Get the CSV file path from command-line arguments
  args <- getArgs
  case args of
    [csvFilePath] -> do
      -- Connect to the MySQL database
      conn <- connect defaultConnectInfo
        { connectHost = "127.0.0.1"  -- or "localhost"
        , connectUser = "root"       -- your MySQL username
        , connectPassword = "my-secret-pw"  -- your MySQL root password
        , connectDatabase = "INTERNET_SUBSCRIPTION"
        }

      -- Import CSV file and insert data into the database
      importCSVAndInsert csvFilePath conn

      -- Close the connection
      close conn
    _ -> putStrLn "Usage: runhaskell Main.hs <path-to-csv-file>"
