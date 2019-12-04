import Weigh
import LocalUtils
import Algos
import Control.Monad
import Text.Printf

benchEditionDistanceAtSize :: Int -> ADNInstance -> Weigh ()
benchEditionDistanceAtSize n inst = do
  when (n <= 13) $ func (printf "dist_naif(%d)" n) (dist_naif :: ADNInstance -> Int) inst
  -- func (printf "dist_2(%d)" n) dist_2 inst
  -- when (n <= 5000) $ func (printf "dist_1(%d)" n) dist_1 inst
  -- when (n <= 5000) $ func (printf "prog_dyn(%d)" n) prog_dyn inst
  -- func (printf "sol_2(%d)" n) sol_2 inst

loadEnvironment :: Int -> IO (Int, ADNInstance)
loadEnvironment n = do
  inst <- setupEnv n
  return (n, inst)

main = do
  insts <- (mapM loadEnvironment [10, 12, 13, 14, 15, 20, 50, 100, 500, 1000, 2000, 3000, 5000, 10000])

  mainWith $ do
    setColumns [Case, Max, GCs]
    forM_ insts (\(n, inst) -> wgroup (printf "Instances de taille %d" n) (benchEditionDistanceAtSize n inst))
