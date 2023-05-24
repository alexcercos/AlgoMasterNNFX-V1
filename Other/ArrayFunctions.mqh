#include "../Other/MinHeap.mqh"

template<typename T>
T ArrayFunctions_SumArray(T &array[])
{
	int t = ArraySize(array);
	
	T value = T(0);
	
	for (int i=0; i<t; i++)
		value+=array[i];
	
	return value;
}

template<typename T>
void ArrayFunctions_AddAtEnd(T &array[], int &total, T element, int reserve=0)
{
	ArrayResize(array, total+1, reserve);
	array[total] = element;
	total++;
}

template<typename T>
void ArrayFunctions_AddAtEndUntracked(T &array[], T element, int reserve=0)
{
	int total = ArraySize(array);
	ArrayResize(array, total+1, reserve);
	array[total] = element;
}

template<typename T>
T ArrayFunctions_PopLast(T &array[],int &total)
{
	if (total==0) return NULL;

	T to_return = array[total-1];
	
	total--;
	ArrayResize(array, total);
	return to_return;
}

template<typename T>
int ArrayFunctions_BinarySearch(T &array[], T search)
{
	int min_i = 0;
	int max_i = ArraySize(array)-1;
	
	while (min_i<max_i)
	{
		int half = (max_i + min_i)/2;
		if (array[half] > search)
			max_i = half - 1;
		
		else if (array[half] < search)
			min_i = half + 1;
			
		else
			return half; //Element found
	}
	
	return min_i;
}

template<typename T>
void ArrayFunctions_Sort(T &array[])
{
	CMinHeap<T> * heap = new CMinHeap<T>(array);
	
	int total = heap.Size();
	for (int i=0; i<total; i++)
	{
		array[i] = heap.Peek();
		heap.RemoveTop();
	}
	
	delete heap;
}
