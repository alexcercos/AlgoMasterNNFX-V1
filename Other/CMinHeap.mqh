//TODO remove (use other minheap)
#define LEFT_CHILD(i) 2 * i + 1
#define RIGHT_CHILD(i) 2 * i + 2
#define PARENT(i) i / 2 - 1

template<typename T>
void MinHeapify(T &array[])
{
   int size = ArraySize(array);
   
   for (int i = size/2 - 1; i>=0; i--)
   {
      Sink(array, size, i);
   }
}

template<typename T>
bool IsMinHeap(T &array[])
{
   return IsMinHeap(array, 0, ArraySize(array));
}

template<typename T>
bool IsMinHeap(T &array[], int index, int size)
{
   if (LEFT_CHILD(index) >= size) return true;
   
   if (RIGHT_CHILD(index) >= size) return array[index] < array[LEFT_CHILD(index)];
   
   return array[index] < array[LEFT_CHILD(index)] &&
          array[index] < array[RIGHT_CHILD(index)] &&
          IsMinHeap(array, LEFT_CHILD(index), size) &&
          IsMinHeap(array, RIGHT_CHILD(index), size);
}


template<typename T>
void Sink(T &heap[], int size, int index)
{
   int minimum = index;
   
   int left = LEFT_CHILD(index);
   int right = RIGHT_CHILD(index);
   
   if (left < size && heap[left] < heap[minimum])
   {
      minimum = left;
   }
   
   if (right < size && heap[right] < heap[minimum])
   {
      minimum = right;
   }
   
   if (minimum != index)
   {
      Swap(heap, minimum, index);
      Sink(heap, size, minimum);
   }
}

template<typename T>
void Rise(T &heap[], int index)
{
   int parent = PARENT(index);
   
   if (parent >= 0 && heap[index] < heap[parent])
   {
      Swap(heap, index, parent);
      Rise(heap, parent);
   }
}

template<typename T>
void Swap(T &array[], int position1, int position2)
{
   T aux = array[position1];
   array[position1] = array[position2];
   array[position2] = aux;
}

template<typename T>
T Peek(T &heap[])
{
   return heap[0];
}

template<typename T>
void RemoveTop(T &heap[])
{
   int size = ArraySize(heap);
   
   Swap(heap, 0, size-1);
   
   ArrayResize(heap, size-1);
   
   Sink(heap, size-1, 0);
}

template<typename T>
void RemoveAtIndex(T &heap[], int index)
{
   int size = ArraySize(heap);
   
   if (index >= size) return;
   
   Swap(heap, index, size-1);
   
   ArrayResize(heap, size-1);
   
   Sink(heap, size-1, index);
}

template<typename T>
void AddElement(T &heap[], T element)
{
   int size = ArraySize(heap);
   
   ArrayResize(heap, size+1);
   
   heap[size] = element;
   
   Rise(heap, size);
}

#undef LEFT_CHILD
#undef RIGHT_CHILD
#undef PARENT
