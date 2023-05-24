
#define LEFT_CHILD(i) 2 * i + 1
#define RIGHT_CHILD(i) 2 * i + 2
#define PARENT(i) (i+1) / 2 - 1

template<typename T>
class CMinHeap
{
	protected:
		T	m_heap[];
		int size;
		
		void Heapify();
		
		void Swap(int position1, int position2);
		void Sink(int index);
		void Rise(int index);
		
	public:
		CMinHeap();
		CMinHeap(T &array[]);
		
		T Peek();
		void RemoveTop();
		T GetAtIndex(int index);
		void RemoveAtIndex(int index);
		
		void AddElement(T element);
		
		void PrintHeap();
		
		int Size() { return size; }
};

template<typename T>
CMinHeap::CMinHeap():size(0)
{
}

template<typename T>
CMinHeap::CMinHeap(T &array[])
{
	ArrayCopy(m_heap, array);
	size = ArraySize(m_heap);
	
	Heapify();
}

template<typename T>
void CMinHeap::Heapify()
{
   for (int i = size/2 - 1; i>=0; i--)
   {
      Sink(i);
   }
}

template<typename T>
void CMinHeap::Swap(int position1, int position2)
{
   T aux = m_heap[position1];
   m_heap[position1] = m_heap[position2];
   m_heap[position2] = aux;
}

template<typename T>
void CMinHeap::Sink(int index)
{
   int minimum = index;
   
   int left = LEFT_CHILD(index);
   int right = RIGHT_CHILD(index);
   
   if (left < size && m_heap[left] < m_heap[minimum])
   {
      minimum = left;
   }
   
   if (right < size && m_heap[right] < m_heap[minimum])
   {
      minimum = right;
   }
   
   if (minimum != index)
   {
      Swap(minimum, index);
      Sink(minimum);
   }
}

template<typename T>
void CMinHeap::Rise(int index)
{
   int parent = PARENT(index);
   
   if (parent >= 0 && m_heap[index] < m_heap[parent])
   {
      Swap(index, parent);
      Rise(parent);
   }
}

template<typename T>
T CMinHeap::Peek()
{
   return m_heap[0];
}

template<typename T>
void CMinHeap::RemoveTop()
{
   Swap(0, size-1);
   
   size--;
   ArrayResize(m_heap, size);
   
   Sink(0);
}

template<typename T>
T CMinHeap::GetAtIndex(int index)
{
	return m_heap[index];
}

template<typename T>
void CMinHeap::RemoveAtIndex(int index)
{
   if (index >= size) return;
   
   Swap(index, size-1);
   
   size--;
   ArrayResize(m_heap, size);
   
   Sink(index);
}

template<typename T>
void CMinHeap::AddElement(T element)
{
   ArrayResize(m_heap, size+1);
   
   m_heap[size] = element;
   
   Rise(size);
   
   size++;
}