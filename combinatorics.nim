import sequtils

iterator choose*[T](a: openarray[T], num_choose: int): seq[T] =
  var
    chosen = newSeqOfCap[T](num_choose)
    i = 0
    i_stack = newSeqOfCap[int](num_choose)
  
  while true:
    if chosen.len == num_choose:
      yield chosen
      discard chosen.pop()
      i = i_stack.pop() + 1
    elif i != a.len:
      chosen.add(a[i])
      i_stack.add(i)
      inc i
    elif i_stack.len > 0:
      discard chosen.pop()
      i = i_stack.pop() + 1
    else:
      break

proc sum*[T](it: openArray[T]): T =
  foldl(it, a + b, 0)

proc sumIterator[T](it: iterator: T): T =
  foldl(it, a + b, 0)

