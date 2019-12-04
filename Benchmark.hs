import LocalUtils
import Data.List.Split
import Algos
import Criterion.Main
import Text.Printf
import System.Random (randomRIO)

sizeFromFilePath :: FilePath -> Int
sizeFromFilePath f = (read ((splitOn "_" f) !! 2)) :: Int

filterBySize :: (Int -> Bool) -> [FilePath] -> [FilePath]
filterBySize p = filter (\f -> p $ sizeFromFilePath f)

setupEnv n = do
  testfiles <- get_testfiles_in_directory "Instances_genome"
  all <- load_testfiles (filterBySize (== n) testfiles)
  random_filecase <- ((all !!) <$> randomRIO (0, length all - 1))
  return (file_input random_filecase)

benchAtSize :: Int -> Benchmark
benchAtSize n =
  env (setupEnv n) $ \inst -> bgroup (printf "Mesure de la performance des instances de taille %d" n) [ bgroup "Distance d'édition" [
  bench "dist_naif" $ nf (dist_naif :: ADNInstance -> Int) inst,
  bench "dist_1" $ nf dist_1 inst,
  bench "dist_2" $ nf dist_2 inst
                                                                                                                                     ]
                                                                                                      ]
main = do
  defaultMain (map benchAtSize [10, 100, 500, 1000, 2000, 3000, 5000])
