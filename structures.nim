import algorithm
import locks
import sequtils
import sets
import strformat
import strutils
import topology

type
  Known* = array[FACES, int]
  Potential* = object
    data*: array[FACES, array[MAX_SUM+1, bool]]
    possibilities*: array[FACES, int]
    known*: Known
    counts*: array[SUMS, int]
  ImpossibleError* = object of ValueError

proc newKnown*(s: string): Known =
  let data = s.strip().splitlines().filterIt(it[0] != '#').mapIt(it.split(" "))
  for pair in data:
    let
      face = pair[0].parseInt - 1
      value = pair[1].parseInt

    result[face] = value

proc initPotential*(): Potential =
  for p in pents:
    result.data[p].fill(MIN_V, MAX_V, true)
    result.possibilities[p] = MAX_V - MIN_V + 1
  for t in tris:
    result.data[t].fill(MIN_SUM, MAX_SUM, true)
    result.possibilities[t] = MAX_SUM - MIN_SUM + 1

proc initPotential*(known: Known): Potential =
  result = initPotential()
  for k, v in known:
    if v == 0:
      continue
    result.data[k].fill(0, MAX_SUM, false)
    result.data[k][v] = true
    result.possibilities[k] = 1
    if k in triSet:
      result.counts[v - MIN_SUM] += 1

  result.known = known

proc `$`*(p: Potential): string =
  for i, r in p.data:
    result &= fmt"{i+1:2d}: "
    for v in r:
      result &= $(int(v))
    if p.known[i] > 0:
      result &= " = " & $(p.known[i]) & "\n"
    else:
      result &= " (" & $(p.possibilities[i]) & ")\n"

proc setTo*(p: var Potential, face: int, value: int) =
  p.data[face].fill(0, MAX_SUM, false)
  p.data[face][value] = true
  p.possibilities[face] = 1
  p.known[face] = value
  if face in triSet:
    p.counts[value - MIN_SUM] += 1

proc setFalse*(p: var Potential, face: int, value: int) {.inline.} =
  if value < 0 or value > MAX_SUM:
    return
  if p.data[face][value]:
    p.possibilities[face] -= 1
    p.data[face][value] = false
    if p.possibilities[face] == 1:
      for v in 0..MAX_SUM:
        if p.data[face][v]:
          p.known[face] = v
          if face in triSet:
            p.counts[v - MIN_SUM] += 1
          break
    if p.possibilities[face] <= 0:
      raise newException(ImpossibleError, fmt"Last possibility for face {face+1} ({value}) was removed")

proc `or`*(p: Potential, q: Potential): Potential =
  for face in 0..<FACES:
    for i in 0..MAX_SUM:
      result.data[face][i] = p.data[face][i] or q.data[face][i]
      if result.data[face][i]:
        result.possibilities[face] += 1
    if result.possibilities[face] == 1:
      for i in 0..MAX_SUM:
        if result.data[face][i]:
          result.known[face] = i
          if face in triSet:
            result.counts[i - MIN_SUM] += 1
          break

