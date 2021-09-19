import algorithm
import intsets
import os
import sequtils
import strformat
import tables
import threadpool
{.experimental: "parallel".}

import combinatorics
import structures
import topology

const MAX_GUESS_DEPTH = 2
const MAX_GUESS_POSSIBILITIES = 5

var values: Known

### Checks

proc trisAreSumsOfAdj(verbose: bool = false): bool =
  for tri in tris:
    let t = adjTable[tri].mapIt(values[it]).foldl(a + b, 0)
    if t != values[tri]:
      if verbose:
        echo fmt"tri {tri+1} has value {values[tri]} but adjacent faces sum to {t}"
      return false

  true

proc pentsHaveSmallVals(verbose: bool = false): bool =
  for pent in pents:
    if values[pent] > 9:
      if verbose:
        echo fmt"pent {pent+1} has value {values[pent]} which is too large"
      return false

  true

proc trisHaveUniqueSurrounds(verbose: bool = false): bool =
  for tri in tris:
    var seen: array[10, bool]
    for t in adjTable[tri]:
      if seen[values[t]]:
        if verbose:
          echo fmt"tri {tri+1} has two adjacent pents with value {values[t]}"
        return false
      seen[values[t]] = true

  true

proc valid(verbose: bool = false): bool =
  pentsHaveSmallVals(verbose) and
  trisAreSumsOfAdj(verbose) and
  trisHaveUniqueSurrounds(verbose)

### Solver

var sums = initTable[int, seq[seq[int]]]()
for n in MIN_SUM..MAX_SUM:
  sums[n] = toSeq(choose((MIN_V..MAX_V).toSeq, SUMMANDS)).filterIt(sum(it) == n)

var canMakeSum = initTable[int, IntSet]()
for n in MIN_SUM..MAX_SUM:
  canMakeSum[n] = initIntSet()
  for combo in sums[n]:
    for i in combo:
      canMakeSum[n].incl(i)

proc applySum(poss: Potential, t: int): array[SUMS, bool] {.gcsafe.} =
  # iterate through possibilities of adjacent pents
  for i, possible in poss.data[adjTable[t][0]]:
    if not possible: continue
    for j, possible in poss.data[adjTable[t][1]]:
      if not possible: continue
      if j == i: continue
      for k, possible in poss.data[adjTable[t][2]]:
        if not possible: continue
        if k == j or k == i: continue

        result[i + j + k - MIN_SUM] = true

proc applySums(poss: Potential): Potential =
  var possSums: array[TRIS, array[SUMS, bool]]
  result = poss
  parallel:
    for i, t in tris:
      possSums[i] = spawn applySum(poss, t)

  for i, t in tris:
    for n in 0..SUMS-1:
      if not possSums[i][n]:
        result.setFalse(t, n+MIN_SUM)

proc applyRSum(poss: ptr Potential, t: int) =
  for pv in MIN_V..MAX_V:
    var pvPoss = false
    for tv, possible in poss.data[t]:
      if not possible: continue
      if pv in canMakeSum[tv]:
        pvPoss = true
        break
    if pvPoss == false:
      for p in adjTable[t]:
        poss[].setFalse(p, pv)

proc applyRSums(poss: Potential): Potential =
  result = poss
  for t in tris:
    applyRSum(addr(result), t)

proc applyTriUniqueness(poss: Potential): Potential =
  #result = poss
  #for t in tris:
  #  if result.known[t] == 0:
  #    for v in 0..<SUMS:
  #      if ((v + MIN_SUM) mod 5) != 1 and result.counts[v] > 0:
  #        result.setFalse(t, v + MIN_SUM)
  #      elif result.counts[v] > 1:
  #        result.setFalse(t, v + MIN_SUM)

    #var tv = poss.known[t]
    #if tv > 0:
    #  if (tv mod 6) != 0:
    #    for t2 in tris:
    #      if t2 == t: continue
    #      result.setFalse(t2, tv)
    #  else:

  result = poss
  for p in pents:
    var
      t1 = adjTable[p][0]
      t2 = adjTable[p][1]
      t3 = adjTable[p][2]
      t4 = adjTable[p][3]
      t5 = adjTable[p][4]
    if result.known[t1] > 0:
      result.setFalse(t2, result.known[t1])
      result.setFalse(t3, result.known[t1])
      result.setFalse(t4, result.known[t1])
      result.setFalse(t5, result.known[t1])
    if result.known[t2] > 0:
      result.setFalse(t1, result.known[t2])
      result.setFalse(t3, result.known[t2])
      result.setFalse(t4, result.known[t2])
      result.setFalse(t5, result.known[t2])
    if result.known[t3] > 0:
      result.setFalse(t1, result.known[t3])
      result.setFalse(t2, result.known[t3])
      result.setFalse(t4, result.known[t3])
      result.setFalse(t5, result.known[t3])
    if result.known[t4] > 0:
      result.setFalse(t1, result.known[t4])
      result.setFalse(t2, result.known[t4])
      result.setFalse(t3, result.known[t4])
      result.setFalse(t5, result.known[t4])
    if result.known[t5] > 0:
      result.setFalse(t1, result.known[t5])
      result.setFalse(t2, result.known[t5])
      result.setFalse(t3, result.known[t5])
      result.setFalse(t4, result.known[t5])

proc applyPentUniqueness(poss: Potential): Potential =
  result = poss
  for t in tris:
    var
      p1 = adjTable[t][0]
      p2 = adjTable[t][1]
      p3 = adjTable[t][2]
    if result.known[p1] > 0:
      result.setFalse(p2, result.known[p1])
      result.setFalse(p3, result.known[p1])
    if result.known[p2] > 0:
      result.setFalse(p1, result.known[p2])
      result.setFalse(p3, result.known[p2])
    if result.known[p3] > 0:
      result.setFalse(p1, result.known[p3])
      result.setFalse(p2, result.known[p3])

proc applyNeighbourNeighbourTheorem(poss: Potential): Potential =
  # Every pentagon except the one directly opposite a given pentagon is either
  # adjacent to a shared triangle and hence different according to the rules
  # *or* a neighbour-of-a-neighbour, which is provably different due to shared
  # triangles being different.
  # Hence this rule applies both the given uniqueness and this property.
  result = poss
  for p in pents:
    if poss.known[p] > 0:
      for q in pents:
        if q != p and q != oppTable[p]:
          result.setFalse(q, result.known[p])

proc solve(poss: var Potential, guess_depth: int = 0, verbose: bool = false)

proc guess(poss: Potential, guess_depth: int): Potential =
  # Strategy: sort faces by how many possible values they have
  # starting with the most constrained (that are still unknown) guess each
  # remaining possibility in turn. If anything leads to an impossible situation
  # then that guess was wrong. If not, we may still get information: the
  # new set of possibilities is the boolean OR of all possibilities seen over
  # all guesses.
  
  var
    # temp variable for storing the current guess scenario
    guessPotential: Potential
    # avoid returning all-zero result
    doneSomething = false

  var priority = sorted(toSeq(0..<FACES), proc (x, y: int): int =
    cmp(poss.possibilities[x], poss.possibilities[y])
  )
  for face in priority:
    if poss.possibilities[face] == 1 or poss.possibilities[face] > MAX_GUESS_POSSIBILITIES:
      # We can't get new info from known faces, and if there are many possibilities it takes
      # too long to go through them all.
      continue
    for g, v in poss.data[face]:
      if not v: continue

      doneSomething = true

      guessPotential = poss
      guessPotential.setTo(face, g)
      try:
        # BFS: round 1 solve but don't permit guessing
        # BFS: round n+1 load guessPotential from (face, g), permit n+1 guess depth
        solve(guessPotential, guess_depth+1)
      except ImpossibleError:
        # This guess results in a contradiction, so it's definitely
        # wrong.
        guessPotential = poss
        guessPotential.setFalse(face, g)
        # We could carry on guessing, but deciding a value for sure
        # probably gains a lot from the other rules for less effort
        return guessPotential
      # If we get here there was no contradiction (due to `return` above).
      # result starts off all zeroes, so ORing it will just give back guessPotential
      # on the first step
      result = result or guessPotential
      # BFS: save (face, g) -> guessPotential
    if doneSomething and result != poss:
      return result
  return poss

var guesses = 0

proc step(poss: Potential, guess_depth: int, verbose: bool = false): Potential =
  result = applySums(poss)
  if verbose:
    echo "sums"
    echo result
  result = applyRSums(result)
  if verbose:
    echo "reverse sums"
    echo result
  result = applyTriUniqueness(result)
  if verbose:
    echo "uniqueness"
    echo result
  #result = applyPentUniqueness(result)
  #if verbose:
  #  echo "pent uniqueness"
  #  echo result
  result = applyNeighbourNeighbourTheorem(result)
  if verbose:
    echo "pent uniqueness"
    echo result
  if guess_depth < MAX_GUESS_DEPTH and result == poss:
    # only count a new guess if we're not inside a guess
    if guess_depth == 0:
      guesses += 1
    result = guess(result, guess_depth)
    if verbose:
      echo "guess"
      echo result

proc solve(poss: var Potential, guess_depth: int = 0, verbose: bool = false) =
  var
    poss2: Potential
    step = 0

  while true:
    poss2 = step(poss, guess_depth)
    if verbose:
      echo poss2
    if poss2 == poss:
      break
    poss = poss2
    step += 1

  if guess_depth == 0:
    var allknown = true
    for k in poss.known:
      if k == 0:
        allknown = false
        break

    echo "Steps: " & $step & ", total guesses: " & $guesses
    if allknown:
      echo "Solution found!"
      for i, k in poss.known:
        echo fmt"{i+1} {k}"

    else:
      echo "Partial solution found."

values = newKnown(readFile(paramStr(1)))
var poss = initPotential(values)
echo poss

solve(poss, 0, true)
