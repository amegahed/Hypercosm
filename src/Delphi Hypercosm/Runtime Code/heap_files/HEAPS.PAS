unit heaps;


{***************************************************************}
{ |\  /|                                               We Put   }
{ | >< Hypercosm               heaps                   3d       }
{ |/  \|                                               To Work! }
{***************************************************************}
{                                                               }
{       The heap is used to allocate variable sized blocks      }
{       of memory and return them after use.                    }
{                                                               }
{***************************************************************}
{                   Copyright 1996 Abe Megahed                  }
{***************************************************************}


interface
uses
  addr_types, data;


const
  max_heap_size = 16384;
  max_heap_number = 16384;
  max_handles = 16384;


type
  {*********************}
  { heap data structure }
  {*********************}
  heap_data_ptr_type = ^heap_data_type;
  heap_data_type = array[1..max_heap_size] of data_type;


  heap_kind_type = (handle_heap, memref_heap);
  heap_ptr_type = ^heap_type;
  heap_type = record
    kind: heap_kind_type;
    heap_data_ptr: heap_data_ptr_type;
    free_space: heap_index_type;

    {**********************************************}
    { pointers into heap object circular free list }
    {**********************************************}
    first_free, last_free: heap_index_type;

    next: heap_ptr_type;
  end; {heap_type}


  {************************}
  { array of ptrs to heaps }
  {************************}
  heap_array_ptr_type = ^heap_array_type;
  heap_array_type = array[1..max_heap_number] of heap_ptr_type;


  {*********************}
  { handle data structs }
  {*********************}
  heap_addr_type = record
    {************************************************}
    { if the handle is unused, then heap_number = 0  }
    { and heap index contains the number of the next }
    { free handle in the free list.                  }
    {************************************************}
    heap_number: heap_index_type;
    heap_index: heap_index_type;
  end; {heap_addr_type}


  {******************}
  { array of handles }
  {******************}
  handle_array_ptr_type = ^handle_array_type;
  handle_array_type = array[1..max_handles] of heap_addr_type;


  {**************************}
  { heap allocation routines }
  {**************************}
function New_heap(kind: heap_kind_type): heap_ptr_type;
procedure Free_heap(var heap_ptr: heap_ptr_type);

{*******************************}
{ heap node allocation routines }
{*******************************}
function Found_free_space(heap_ptr: heap_ptr_type;
  size: heap_index_type): boolean;
procedure Allocate_heap_space(heap_ptr: heap_ptr_type;
  backptr: heap_index_type;
  size: heap_index_type);
procedure Free_heap_node(heap_ptr: heap_ptr_type;
  free_index: heap_index_type;
  free_elements: boolean);

{**************************}
{ heap management routines }
{**************************}
procedure Compact_heap(heap_ptr: heap_ptr_type;
  handle_array_ptr: handle_array_ptr_type);
procedure Check_heap_free_list(heap_ptr: heap_ptr_type);


implementation
uses
  errors, new_memory, data_types, handles;


{*******************************************************}
{         implementation of heap data structs           }
{*******************************************************}
{                                                       }
{               heap object organization:               }
{                                                       }
{       There are two types of heap objects: objects    }
{       which are in use and objects which are not      }
{       in use.                                         }
{                                                       }
{                in use:        not in use:             }
{                                                       }
{               |--------|      |--------|              }
{               |back ptr|      |  next  |              }
{               |--------|      |--------|              }
{               |        |      |        |              }
{               |  data  |      |        |              }
{               |        |      |        |              }
{               |--------|      |--------|              }
{               |refcount|      |   -1   |              }
{               |--------|      |--------|              }
{               |  size  |      |  size  |              }
{               |--------|      |--------|              }
{                                                       }
{                                                       }
{                     objects in use:                   }
{       Objects which are in use have three extra       }
{       fields besides the data: the size field,        }
{       the backpointer field, and the reference        }
{       count field. The size field is needed so        }
{       that when the object is thrown back onto        }
{       the free list, we know how big it is for        }
{       furthur allocation. The backpointer field       }
{       is needed so that when the heap is compacted,   }
{       then we can rearrange the pointers into the     }
{       heap. The reference count field allows us       }
{       to do garbage collection, collecting all        }
{       of the objects which are unreferenced and       }
{       returning them automatically to the free        }
{       list.                                           }
{                                                       }
{                    objects not in use:                }
{       Objects which are not in use have two fields    }
{       of concern: the size field and the next field.  }
{       The size field is needed when we are searching  }
{       the free list for a heap object big enough to   }
{       accomadate some data. The next field points     }
{       to the next available heap object.              }
{                                                       }
{       The stack is implemented as an array so         }
{       the next field is an index to the next          }
{       available heap object.                          }
{                                                       }
{       The backpointer is a pointer to the heap_addr   }
{       which tells the location of the heap object.    }
{*******************************************************}


{*******************************************************}
{            illustration of heap operations            }
{*******************************************************}
{                                                       }
{                                                       }
{                       the heap:                       }
{       |---------------------------------------|       }
{       |        |free|  |free|  |free|         |       }
{       |---------------------------------------|       }
{                 |  ^    |  ^    |  ^                  }
{                 |  |    |  |    |  |                  }
{                 -  \----/  \----/  \--free space ptr  }
{                                                       }
{                                                       }
{       When a request for space is received, we        }
{       traverse the list of free nodes to find         }
{       one big enough to satisfy the request.          }
{                                                       }
{                  Traversing the List:                 }
{       The list of nodes is circular and whenever      }
{       a new search commences, it begins wherever      }
{       the previous search left off.  This keeps       }
{       the searches from becoming too localized        }
{       and prevents the free list from getting too     }
{       fragmented near the beginning.                  }
{                                                       }
{       If necessary, we may need to compact the        }
{       heap to find a contiguous block of the          }
{       required size.                                  }
{                                                       }
{       If the heap does not contain enough space       }
{       to satisfy the request, then another heap       }
{       must be created.                                }
{                                                       }
{       Once this node is found, we must split it       }
{       into two parts: the used part and the unused    }
{       part.                                           }
{                                                       }
{*******************************************************}


{*******************************************************}
{          allocating space from the free list          }
{*******************************************************}
{                                                       }
{       when a node of sufficient size is found on      }
{       the free list, there are 2 cases:               }
{                                                       }
{       1) inexact match                                }
{          node must be split - part is used and        }
{          part remains on the free list.               }
{                                                       }
{       2) exact match                                  }
{          entire node is removed from free list        }
{                                                       }
{*******************************************************}


{*******************************************************}
{                 splitting a heap node                 }
{*******************************************************}
{                                                       }
{       when splitting a heap node, there are 2         }
{       cases to account for:                           }
{                                                       }
{       1) first <> last:                               }
{                                                       }
{                        before:                        }
{       -----------    -----------    -----------       }
{       |  free   |--->|  free   |--->|  free   |       }
{       -----------    -----------    -----------       }
{       ^              ^                                }
{       |              |                                }
{     last           first                              }
{                                                       }
{                         after:                        }
{       -----------    -----------    -----------       }
{       |  free   |--\ |used|free|--->|  free   |       }
{       -----------  | -----------    -----------       }
{       ^            |      ^                           }
{       |            \------|                           }
{     last                first                         }
{                                                       }
{*******************************************************}
{                                                       }
{       2) first = last                                 }
{                                                       }
{                        before:                        }
{                      -----------                      }
{                      |  free   |---\                  }
{                      -----------   |                  }
{                       ^            |                  }
{                       |------------/                  }
{                  last, first, next                    }
{                                                       }
{                                                       }
{                         after:                        }
{                      -----------                      }
{                      |used|free|---\                  }
{                      -----------   |                  }
{                           ^        |                  }
{                           |--------/                  }
{                       last, first, next               }
{                                                       }
{*******************************************************}


{*******************************************************}
{           removing a node from the free list          }
{*******************************************************}
{                                                       }
{       when removing a heap node from the free         }
{       list, there are 2 cases to account for:         }
{                                                       }
{       1) first <> last:                               }
{                                                       }
{                        before:                        }
{       -----------    -----------    -----------       }
{       |  free   |--->|  free   |--->|  free   |       }
{       -----------    -----------    -----------       }
{       ^              ^                                }
{       |              |                                }
{     last           first                              }
{                                                       }
{                         after:                        }
{       -----------    -----------    -----------       }
{       |  free   |--\ |  used   |    |  free   |       }
{       -----------  | -----------    -----------       }
{       ^            |                ^                 }
{       |            \----------------|                 }
{     last                          first               }
{                                                       }
{*******************************************************}
{                                                       }
{       2) first = last                                 }
{                                                       }
{                        before:                        }
{                      -----------                      }
{                      |  free   |---\                  }
{                      -----------   |                  }
{                       ^            |                  }
{                       |------------/                  }
{                  last, first, next                    }
{                                                       }
{                                                       }
{                         after:                        }
{                      -----------                      }
{                      |  used   |                      }
{                      -----------                      }
{                                                       }
{                   last, first = nil!                  }
{              (used nodes have no next ptr)            }
{                                                       }
{*******************************************************}


{*******************************************************}
{       pointer values used in splitting a heap node    }
{*******************************************************}
{                                                       }
{       example:                                        }
{       x: number of units requested from heap = 2      }
{       size1: size of free heap object = 8             }
{       size2: size of new heap object = size1-x-3 = 3  }
{       addr1: addr of free heap object = 0             }
{       addr2: addr of next field = addr1+size1+2 = 10  }
{       addr3: addr of new free object = addr1+x+3 = 5  }
{       next: addr of next free heap object             }
{       prev: addr of previous next field               }
{                                                       }
{                                                       }
{                 before:         after:                }
{                                                       }
{               |-------|       |-------|               }
{       addr2 ->| next  |  10   | next  |               }
{               |-------|       |-------|               }
{               |   8   |   9   |   3   |               }
{               |-------|       |-------|               }
{               |   7   |   8   |   2   |               }
{               |-------|       |-------|               }
{               |   6   |   7   |   1   |               }
{               |-------|       |-------|               }
{               |   5   |   6   |  -1   |               }
{               |-------|       |-------|               }
{               |   4   |   5/->| size2 |<- addr3       }
{               |-------|    |  |-------|               }
{               |   3   |   4|  |backptr|               }
{               |-------|    |  |-------|               }
{               |   2   |   3|  |   2   |               }
{               |-------|    |  |-------|               }
{               |   1   |   2|  |   1   |               }
{               |-------|    |  |-------|               }
{               |  -1   |   1|  |count=1|               }
{               |-------|    |  |-------|               }
{       addr1 ->| size1 |   0|  |  x=2  |               }
{               |-------|    |  |-------|               }
{                   ^        |                          }
{                   |        \------\                   }
{                   |               |                   }
{                 prev            prev                  }
{                                                       }
{*******************************************************}


{*******************************************************}
{           steps for allocating a heap node:           }
{*******************************************************}
{       1. search heaps for one with enough free        }
{          space                                        }
{       2. if not found, then create a new heap         }
{       3. search free list for a big enough node       }
{       4. if not found, compact heap and repeat        }
{                                                       }
{       once we find a heap object big enough, we       }
{       must split it into two pieces, the piece of     }
{       the requested size, and the remaining piece.    }
{       This is done as follows:                        }
{                                                       }
{       1. compute addr of start of remaining piece     }
{          and set the previous node's next field       }
{          to point to it instead of pointing to the    }
{          beginning of the node which we are using.    }
{       2. create new handle and initialize to point    }
{          to the block of memory that we have just     }
{          allocated.                                   }
{       3. set backpointer of new heap object to        }
{          point to the handle.                         }
{*******************************************************}


{*******************************************************}
{            steps for freeing a heap node:             }
{*******************************************************}
{       Using 'smart' garbage collection:               }
{       1. add handle to handle free list               }
{       2. decrease reference count field               }
{       3. if reference count = 0, then                 }
{          recursively free and objects pointed to      }
{          by handles contained in the object           }
{       4. add object to head of free list              }
{                                                       }
{       Using 'dumb' garbage collection:                }
{       1. add handle to handle free list               }
{       2. decrease reference count field               }
{       3. decrease reference count field of any        }
{          objects pointed to by handles contained      }
{          in this object.                              }
{       4. add object to head of free list              }
{       5. objects with a reference count of 0 will be  }
{          cleaned up at a later time.                  }
{*******************************************************}


const
  debug = false;
  new_heap_notify = false;
  compaction_notify = false;
  free_list_checking = false;


  {*********************}
  { diagnostic routines }
  {*********************}


procedure Check_heap_free_list(heap_ptr: heap_ptr_type);
var
  first_index, last_index: heap_index_type;
  start, node_size: heap_index_type;
begin
  if debug then
    writeln('checking circular free list');

  start := heap_ptr^.first_free;
  first_index := heap_ptr^.first_free;
  last_index := heap_ptr^.last_free;

  repeat
    {*****************************}
    { goto next node in free list }
    {*****************************}
    if (first_index <> last_index) then
      begin
        last_index := first_index;

        node_size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[first_index]);
        first_index := Data_to_heap_index(heap_ptr^.heap_data_ptr^[first_index +
          node_size + 2]);

        if (first_index < 1) or (first_index > max_heap_size) then
          Error('bad circular heap free list');
      end;
  until (first_index = start);
end; {procedure Check_heap_free_list}


procedure Write_heap_free_list(heap_ptr: heap_ptr_type);
var
  index, size, next: heap_index_type;
  reference_count: integer_type;
begin
  index := heap_ptr^.first_free;
  while index <> 0 do
    begin
      size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[index]);
      reference_count := Data_to_integer(heap_ptr^.heap_data_ptr^[index + 1]);
      write('free heap object with ');
      write('size = ', size: 1);
      write(', index = ', index: 1);
      write(', rc = ', reference_count: 1);
      writeln('.');
      next := index + size + 2;
      index := Data_to_heap_index(heap_ptr^.heap_data_ptr^[next]);
      if index = heap_ptr^.first_free then
        index := 0;
    end;
end; {procedure Write_heap_free_list}


procedure Write_heap_used_list(heap_ptr: heap_ptr_type);
var
  index, size: heap_index_type;
  reference_count: integer_type;
begin
  index := 1;
  while index < max_heap_size do
    begin
      size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[index]);
      reference_count := Data_to_integer(heap_ptr^.heap_data_ptr^[index + 1]);
      if reference_count <> -1 then
        begin
          write('used heap object with ');
          write('size = ', size: 1);
          write(', index = ', index: 1);
          writeln('.');
        end;
      index := index + size + 3;
    end;
end; {procedure Write_heap_used_list}


procedure Write_heap(heap_ptr: heap_ptr_type);
begin
  writeln('writing heap...');
  writeln('free heap nodes:');
  Write_heap_free_list(heap_ptr);
  writeln('used heap nodes:');
  Write_heap_used_list(heap_ptr);
  writeln;
end; {procedure Write_heap}


{**************************}
{ heap allocation routines }
{**************************}


function New_heap(kind: heap_kind_type): heap_ptr_type;
var
  heap_ptr: heap_ptr_type;
  counter: heap_index_type;
begin
  if new_heap_notify then
    writeln('allocating new heap');
  new(heap_ptr);

  {*****************}
  { initialize heap }
  {*****************}
  heap_ptr^.kind := kind;
  with heap_ptr^ do
    begin
      new(heap_data_ptr);

      {**********************************}
      { initialize pointers to free list }
      {**********************************}
      first_free := 1;
      last_free := 1;

      {***********************}
      { initialize size field }
      {***********************}
      free_space := max_heap_size - 3;
      heap_data_ptr^[1] := Heap_index_to_data(free_space);

      {**********************************}
      { initialize reference count field }
      {**********************************}
      heap_data_ptr^[2] := Integer_to_data(-1);

      {****************************************}
      { initialize heap to uninitialized state }
      {****************************************}
      for counter := 3 to max_heap_size - 1 do
        heap_data_ptr^[counter].kind := error_data;

      {***********************}
      { initialize next field }
      {***********************}
      heap_data_ptr^[max_heap_size] := Heap_index_to_data(1);

      next := nil;
    end;

  New_heap := heap_ptr;
end; {function New_heap}


procedure Free_heap(var heap_ptr: heap_ptr_type);
begin
  Free_ptr(ptr_type(heap_ptr));
end; {procedure Free_heap}


{*******************************}
{ heap node allocation routines }
{*******************************}


function Found_free_space(heap_ptr: heap_ptr_type;
  size: heap_index_type): boolean;
var
  start, node_size: heap_index_type;
  found: boolean;
begin
  {**********************************************}
  { note that this routine updates the pointers, }
  { first_free and last_free as it traverses the }
  { circular free list.  If a node is found with }
  { the necessary space, it will be pointed to   }
  { by first_free when this routine ends.        }
  {**********************************************}
  found := false;
  start := heap_ptr^.first_free;

  if debug then
    writeln('searching for node of size ', size: 1);

  with heap_ptr^ do
    repeat
      node_size := Data_to_heap_index(heap_data_ptr^[first_free]);
      if (node_size = size) or (node_size >= size + 3) then
        begin
          {*******************************}
          { found a node of adaquate size }
          {*******************************}
          found := true;
        end
      else
        begin
          {*****************************}
          { goto next node in free list }
          {*****************************}
          if debug then
            writeln('rejecting node with size = ', node_size: 1);

          last_free := first_free;
          first_free := Data_to_heap_index(heap_data_ptr^[first_free + node_size
            + 2]);
        end;
    until (first_free = start) or found;

  Found_free_space := found;
end; {function Found_free_space}


{**************************}
{ heap management routines }
{**************************}


procedure Compact_heap(heap_ptr: heap_ptr_type;
  handle_array_ptr: handle_array_ptr_type);
var
  source_index, dest_index: heap_index_type;
  counter, index1, index2, size: heap_index_type;
  handle_index: heap_index_type;
  reference_count: integer_type;
begin
  {*****************************************}
  { copy data from source location to dest  }
  { location in the same heap eliminating   }
  { the gaps as we go along and using the   }
  { size and reference count fields to find }
  { the chain of objects which are in use.  }
  {*****************************************}
  if compaction_notify then
    case heap_ptr^.kind of
      handle_heap:
        writeln('compacting handle heap');
      memref_heap:
        writeln('compacting memref heap');
    end; {case}

  if debug then
    writeln('before compaction: free space = ', heap_ptr^.free_space: 1, '.');

  source_index := 1;
  dest_index := 1;
  while (source_index < max_heap_size) do
    begin
      size := Data_to_heap_index(heap_ptr^.heap_data_ptr^[source_index]);
      reference_count := Data_to_integer(heap_ptr^.heap_data_ptr^[source_index +
        1]);

      {************************************}
      { skip through inactive heap objects }
      {************************************}
      while (reference_count = -1) and (source_index < max_heap_size) do
        begin
          source_index := source_index + size + 3;
          if (source_index < max_heap_size) then
            begin
              size :=
                Data_to_heap_index(heap_ptr^.heap_data_ptr^[source_index]);
              reference_count :=
                Data_to_integer(heap_ptr^.heap_data_ptr^[source_index + 1]);
            end;
        end;

      {*********************************}
      { copy object from source to dest }
      {*********************************}
      if (reference_count <> -1) then
        begin
          if debug then
            begin
              write('moving heap object from ', source_index: 1);
              write(' to ', dest_index: 1, ' with size of ', size: 1);
              writeln;
            end;

          if (source_index <> dest_index) then
            for counter := 0 to (size + 2) do
              begin
                index1 := source_index + counter;
                index2 := dest_index + counter;
                heap_ptr^.heap_data_ptr^[index2] :=
                  heap_ptr^.heap_data_ptr^[index1];
              end;

          {************************************************}
          { change handle to reflect relocated heap object }
          {************************************************}
          handle_index :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[source_index + size +
            2]);
          handle_array_ptr^[handle_index].heap_index := dest_index;

          {*************************************}
          { increment source and dest heap ptrs }
          {*************************************}
          source_index := source_index + size + 3;
          dest_index := dest_index + size + 3;
        end;
    end;

  {**************************************}
  { create free node out of rest of heap }
  {**************************************}
  heap_ptr^.first_free := dest_index;
  heap_ptr^.last_free := dest_index;
  heap_ptr^.free_space := max_heap_size - dest_index - 2;

  {****************}
  { set size field }
  {****************}
  heap_ptr^.heap_data_ptr^[dest_index] :=
    Heap_index_to_data(heap_ptr^.free_space);

  {***************************}
  { set reference count field }
  {***************************}
  heap_ptr^.heap_data_ptr^[dest_index + 1] := Integer_to_data(-1);

  {****************}
  { set next field }
  {****************}
  heap_ptr^.heap_data_ptr^[max_heap_size] := Heap_index_to_data(dest_index);

  if debug then
    writeln('after compaction: free space = ', heap_ptr^.free_space: 1, '.');

  if free_list_checking then
    Check_heap_free_list(heap_ptr);
end; {procedure Compact_heap}


procedure Compact_heap2(var heap_ptr: heap_ptr_type;
  heap_array_ptr: heap_array_ptr_type;
  handle_array_ptr: handle_array_ptr_type;
  heap_number: heap_index_type);
var
  heap_ptr1, heap_ptr2: heap_ptr_type;
  source_index, dest_index, index1, index2: heap_index_type;
  counter1, counter2, handle_index: heap_index_type;
  heap_addr: heap_addr_type;
  size: heap_index_type;
begin
  {****************************************************}
  { This heap compaction algorithm uses the handles to }
  { find the heap objects that are in use instead of   }
  { using the reference count field inside the objects }
  { themselves. Since the heap objects may be accessed }
  { out of order, we can not use an in place shuffle   }
  { but must instead copy the objects to a new heap    }
  { and then replace the old heap with the new heap.   }
  {****************************************************}
  if compaction_notify then
    writeln('compacting heap');

  {*****************}
  { create new heap }
  {*****************}
  heap_ptr1 := heap_ptr;
  heap_ptr2 := New_heap(heap_ptr1^.kind);

  {******************************************}
  { copy data from first heap to the second  }
  { heap eliminating the gaps as we go along }
  { using handles as reference into heap.    }
  {******************************************}
  dest_index := 1;
  for counter1 := 1 to max_handles do
    begin
      heap_addr := handle_array_ptr^[counter1];
      if (heap_addr.heap_number = heap_number) then
        begin
          source_index := heap_addr.heap_index;
          size := Data_to_heap_index(heap_ptr1^.heap_data_ptr^[source_index]);

          {***********}
          { copy data }
          {***********}
          for counter2 := 0 to (size + 3) do
            begin
              index1 := source_index + counter2;
              index2 := dest_index + counter2;
              heap_ptr2^.heap_data_ptr^[index2] :=
                heap_ptr1^.heap_data_ptr^[index1];
            end;

          {************************************************}
          { change handle to reflect relocated heap object }
          {************************************************}
          handle_index :=
            Data_to_heap_index(heap_ptr^.heap_data_ptr^[source_index + size +
            2]);
          handle_array_ptr^[handle_index].heap_index := dest_index;

          {**********************************************}
          { increment index of second (destination) heap }
          {**********************************************}
          dest_index := dest_index + size;
        end;
    end;

  {**************************************}
  { create free node out of rest of heap }
  {**************************************}
  heap_ptr2^.first_free := dest_index;
  heap_ptr2^.last_free := dest_index;

  {****************}
  { set size field }
  {****************}
  heap_ptr2^.heap_data_ptr^[dest_index] :=
    Heap_index_to_data(heap_ptr^.free_space);

  {***************************}
  { set reference count field }
  {***************************}
  heap_ptr2^.heap_data_ptr^[dest_index + 1] := Integer_to_data(-1);

  {****************}
  { set next field }
  {****************}
  heap_ptr2^.heap_data_ptr^[max_heap_size] := Heap_index_to_data(0);

  {**************************************}
  { replace the first heap by the second }
  {**************************************}
  Free_heap(heap_ptr);
  heap_array_ptr^[heap_number] := heap_ptr2;
end; {procedure Compact_heap2}


procedure Allocate_heap_node(heap_ptr: heap_ptr_type;
  backptr: heap_index_type);
var
  size, last_size: heap_index_type;
  used_index, next_index: heap_index_type;
  first_next, last_next: heap_index_type;
  counter: heap_index_type;
  data: data_type;
begin
  if debug then
    writeln('allocating whole heap node');

  if free_list_checking then
    Check_heap_free_list(heap_ptr);

  with heap_ptr^ do
    begin
      size := Data_to_heap_index(heap_data_ptr^[first_free]);
      used_index := first_free;

      if (first_free <> last_free) then
        begin
          first_next := first_free + size + 2;
          last_size := Data_to_heap_index(heap_data_ptr^[last_free]);
          last_next := last_free + last_size + 2;
          next_index := Data_to_heap_index(heap_data_ptr^[first_next]);

          {*****************************************}
          { change last next and heap free list ptr }
          {*****************************************}
          heap_data_ptr^[last_next] := Heap_index_to_data(next_index);
          first_free := next_index;
        end
      else
        begin
          {***************************}
          { reset heap free list ptrs }
          {***************************}
          first_free := 0;
          last_free := 0;
        end;

      {****************************************}
      { set reference count of new heap object }
      {****************************************}
      heap_data_ptr^[used_index + 1] := Integer_to_data(1);

      {************************************}
      { set backpointer of new heap object }
      {************************************}
      heap_data_ptr^[used_index + size + 2] := Heap_index_to_data(backptr);

      {*****************}
      { initialize node }
      {*****************}
      data.kind := error_data;
      for counter := used_index + 2 to used_index + size + 1 do
        heap_data_ptr^[counter] := data;
    end;

  if free_list_checking then
    Check_heap_free_list(heap_ptr);
end; {procedure Allocate_heap_node}


procedure Free_heap_node(heap_ptr: heap_ptr_type;
  free_index: heap_index_type;
  free_elements: boolean);
var
  data: data_type;
  index: heap_index_type;
  size, last_size: heap_index_type;
  handle: handle_type;
begin
  with heap_ptr^ do
    begin
      {********************************************}
      { get size of heap object to find next field }
      {********************************************}
      size := Data_to_heap_index(heap_data_ptr^[free_index]);

      {**********************************************}
      { recursively free any referenced heap objects }
      {**********************************************}
      if free_elements then
        for index := (free_index + 2) to (free_index + size + 1) do
          begin
            data := heap_data_ptr^[index];
            if data.kind = handle_data then
              begin
                handle := Data_to_handle(data);
                if handle <> 0 then
                  Free_handle(data.handle);
              end;
          end;

      {********************************************}
      { set reference count to reflect free status }
      {********************************************}
      heap_data_ptr^[free_index + 1] := Integer_to_data(-1);

      {****************************************}
      { add new free node to head of free list }
      {****************************************}
      if (first_free = 0) and (last_free = 0) then
        begin
          {*****************************}
          { set next field of free node }
          {*****************************}
          heap_data_ptr^[free_index + size + 2] :=
            Heap_index_to_data(free_index);

          {***************************}
          { reset heap free list ptrs }
          {***************************}
          first_free := free_index;
          last_free := free_index;
        end
      else
        begin
          {********************************************}
          { get size of heap object to find next field }
          {********************************************}
          last_size := Data_to_heap_index(heap_data_ptr^[last_free]);

          {*********************************************************}
          { set next field of last node and next field of free node }
          {*********************************************************}
          heap_data_ptr^[last_free + last_size + 2] :=
            Heap_index_to_data(free_index);
          heap_data_ptr^[free_index + size + 2] :=
            Heap_index_to_data(first_free);

          {***************************}
          { reset heap free list ptrs }
          {***************************}
          first_free := free_index;
        end;

      {**************************************}
      { increment counter of available space }
      {**************************************}
      free_space := free_space + size + 3;
    end;
end; {procedure Free_heap_node}


procedure Split_heap_node(heap_ptr: heap_ptr_type;
  backptr: heap_index_type;
  size: heap_index_type);
var
  first_size, last_size: heap_index_type;
  used_index, free_index: heap_index_type;
  free_size: heap_index_type;
  counter: heap_index_type;
  data: data_type;
begin
  if debug then
    writeln('splitting heap node');

  if free_list_checking then
    Check_heap_free_list(heap_ptr);

  with heap_ptr^ do
    begin
      {***********************************************}
      { find size of remaining portion of heap object }
      {***********************************************}
      used_index := first_free;
      first_size := Data_to_heap_index(heap_data_ptr^[first_free]);
      free_index := first_free + size + 3;
      free_size := first_size - size - 3;

      if first_size < size + 3 then
        Error('heap allocation error');

      {***********************************}
      { set size of remaining heap object }
      {***********************************}
      heap_data_ptr^[free_index] := Heap_index_to_data(free_size);

      {**********************************************}
      { set reference count of remaining heap object }
      {**********************************************}
      heap_data_ptr^[free_index + 1] := Integer_to_data(-1);

      if (first_free <> last_free) then
        begin
          {*****************************}
          { set next field of last node }
          {*****************************}
          last_size := Data_to_heap_index(heap_data_ptr^[last_free]);
          heap_data_ptr^[last_free + last_size + 2] :=
            Heap_index_to_data(free_index);

          {***************************}
          { reset heap free list ptrs }
          {***************************}
          first_free := free_index;

          if free_list_checking then
            Check_heap_free_list(heap_ptr);
        end
      else
        begin
          {*****************************}
          { set next field of free node }
          {*****************************}
          heap_data_ptr^[free_index + free_size + 2] :=
            Heap_index_to_data(free_index);

          {***************************}
          { reset heap free list ptrs }
          {***************************}
          first_free := free_index;
          last_free := free_index;

          if free_list_checking then
            Check_heap_free_list(heap_ptr);
        end;

      {*****************************}
      { set size of new heap object }
      {*****************************}
      heap_data_ptr^[used_index] := Heap_index_to_data(size);

      {****************************************}
      { set reference count of new heap object }
      {****************************************}
      heap_data_ptr^[used_index + 1] := Integer_to_data(1);

      {************************************}
      { set backpointer of new heap object }
      {************************************}
      heap_data_ptr^[used_index + size + 2] := Heap_index_to_data(backptr);

      {*****************}
      { initialize node }
      {*****************}
      data.kind := error_data;
      for counter := used_index + 2 to used_index + size + 1 do
        heap_data_ptr^[counter] := data;
    end;
end; {procedure Split_heap_node}


procedure Allocate_heap_space(heap_ptr: heap_ptr_type;
  backptr: heap_index_type;
  size: heap_index_type);
var
  first_size: heap_index_type;
begin
  {**************************}
  { allocate space from heap }
  {**************************}
  with heap_ptr^ do
    begin
      {*******************************************}
      { find the size of the heap object selected }
      {*******************************************}
      first_size := Data_to_heap_index(heap_data_ptr^[first_free]);

      if (first_size = size) then
        Allocate_heap_node(heap_ptr, backptr)
      else
        Split_heap_node(heap_ptr, backptr, size);

      {**************************************}
      { decrement counter of available space }
      {**************************************}
      free_space := free_space - size - 3;
    end;
end; {function Allocate_heap_space}


end.
