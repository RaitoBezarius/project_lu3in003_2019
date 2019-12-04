import LocalUtils
import Algos
import Criterion.Main
import Text.Printf

-- Benchmark des fonctions
-- On les passe à Criterion qui va benchmarker ™ (de façon statistiquement signifiante & correct)
-- Ensuite, on passe le CSV à Python qui va préparer les jolis plots avec Pandas

benchAtSize :: Int -> Benchmark
benchAtSize n =
  env (setupEnv n) $ \inst -> bgroup (printf "Mesure de la performance des instances de taille %d" n) [
  bgroup "Distance d'édition" [
  bench "dist_naif" $ whnf (dist_naif :: ADNInstance -> Int) inst]
  -- bench "dist_1 Vector" $ whnf dist_1' inst,
  -- bench "dist_1" $ whnf dist_1 inst,
  -- bench "dist_2" $ whnf dist_2 inst
                                                                                                      --]

--    bgroup "Alignement optimaux" [
--      bench "sol_1" $ whnf prog_dyn inst,
--    bench "sol_1 vector" $ whnf prog_dyn' inst,
--      bench "sol_2" $ nf sol_2 inst
--                                 ]
                                                                                                      ]
main = do
  defaultMain (map benchAtSize [10, 12])
