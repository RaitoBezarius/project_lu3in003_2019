import Test.Tasty
import Test.Tasty.HUnit
import LocalUtils
import Debug.Trace
import Algos

data EDCase = EDCase {
  filename :: FilePath,
  output :: Int
                     }

data EditionDistanceExpectation = EditionDistanceExpectation {
  name :: FilePath,
  input :: ADNInstance,
  expected :: Int
                                                             }


load_expectation :: EDCase -> IO EditionDistanceExpectation
load_expectation c = do
  adn_instance <- read_instance (filename c)
  return EditionDistanceExpectation { name = (filename c), input = adn_instance,  expected = (output c) }

load_expectations :: [EDCase] -> IO [EditionDistanceExpectation]
load_expectations = traverse load_expectation

edition_distance_hardcoded_cases = [
  (EDCase { filename = "Instances_genome/Inst_0000010_44.adn", output = 10 }),
  (EDCase { filename = "Instances_genome/Inst_0000010_7.adn", output = 8 }),
  (EDCase { filename = "Instances_genome/Inst_0000010_8.adn", output = 2 })]

turn_expectation_into_unit_test :: EditionDistanceExpectation -> (String, (ADNInstance -> Int)) -> TestTree
turn_expectation_into_unit_test e (fname, f) =
  testCase ("Test de " ++ fname ++ " sur " ++ (name e)) $ (f (input e) @?= (expected e))

turn_instance_into_property_check :: String -> (a -> [TestTree]) -> (String, a) -> TestTree
turn_instance_into_property_check iname p (gen_name, g) =
  testGroup ("Test de " ++ gen_name ++ " sur " ++ iname) (p g)

-- property checking test
no_gap_at_same_position :: (String, String) -> Bool
no_gap_at_same_position ("", "") = True
no_gap_at_same_position (x : u, y : v) = (x /= '-' || y /= '-') && no_gap_at_same_position (u, v)

mor_pi :: String -> String
mor_pi = filter (\x -> x /= '-')

est_un_alignement_de :: (String, String) -> (String, String) -> [TestTree]
est_un_alignement_de (x, y) (u, v) = [
        testCase "|u| = |v|" ((length u) @=? (length v)),
        testCase "pi(u) = x" (x @=? (mor_pi u)),
        testCase "pi(v) = y" (y @=? (mor_pi v)),
        testCase "pas de gap à la même position" ((no_gap_at_same_position (u, v) @? "Deux gaps à la même position trouvé"))]

edition_distance_functions = [("distance naïve", dist_naif), ("dist_1", dist_1), ("dist_2", dist_2)]
alignement_functions = [("sol_1", prog_dyn, 5000)]

edition_distance_test_group :: [EditionDistanceExpectation] -> [(String, (ADNInstance -> Int))] -> TestTree
edition_distance_test_group exps fns = testGroup "Tests de correction sur la distance d'édition hardcodés"
  [ turn_expectation_into_unit_test e f | e <- exps, f <- fns ]

are_those_alignement_test_group :: [FileCase] -> [(String, (ADNInstance -> (String, String)), Int)] -> TestTree
are_those_alignement_test_group instances fns = testGroup "Test de propriété d'alignement"
  [ turn_instance_into_property_check (case_name inst) (est_un_alignement_de $ (file_input inst)) (ngen, fgen $ (file_input inst)) | inst <- instances, (ngen, fgen, limit) <- fns, size_n inst <= limit ]

tests :: [TestTree] -> TestTree
tests io_dependentTests = testGroup "Tests" io_dependentTests

-- idea: take a VerificationStatus and if that's wrong, take the list of the wrong cases, show all of them
-- show expected vs unexpected
-- if that's right, show cool stuff.
-- show_task_status

main = do
  expectations <- load_expectations edition_distance_hardcoded_cases
  test_files <- get_testfiles_in_directory "Instances_genome"
  putStrLn (show test_files)
  test_instances <- load_testfiles test_files
  defaultMain (tests [ are_those_alignement_test_group test_instances alignement_functions,
    edition_distance_test_group expectations edition_distance_functions ])
