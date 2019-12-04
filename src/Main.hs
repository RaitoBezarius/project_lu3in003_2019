module Main where
  import System.Environment
  import System.Exit
  import Algos
  import LocalUtils

  algorithms :: String -> (ADNInstance -> String)
  algorithms x
    | x == "dist_naif" = show . (dist_naif :: ADNInstance -> Int)
    | x == "dist_1" = show . dist_1
    | x == "dist_2" = show . dist_2
    | x == "prog_dyn" = show .prog_dyn
    | x == "sol_2" = show . sol_2
    | otherwise = error "Algorithme non implémenté"
   

  -- getContents → String
  -- show (algorithms algorithm) ADNInstance

  main :: IO ()
  main = getArgs >>= parse >>= putStrLn

  processInput f [] = (f . instanceFromString) <$> getContents
  processInput f (x:xs) = die ("Not yet handled: " ++ (show (x:xs)))

  parse ["-h"] = usage >> exit
  parse [] = usage >> exit
  parse ("-a" : algorithm : fs) = processInput (algorithms algorithm) fs

  usage = putStrLn "Usage: alignemoi [-h] -a dist_1/dist_2/sol_2/prog_dyn [adn1 ...]"
  exit = exitWith ExitSuccess
