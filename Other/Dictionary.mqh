//+------------------------------------------------------------------+
//|                                                   Dictionary.mqh |
//|                                                   Enrico Lambino |
//|                             https://www.mql5.com/en/users/iceron |
//+------------------------------------------------------------------+
#property copyright "Enrico Lambino."
#property link      "https://www.mql5.com/en/users/iceron"
#include <Arrays\ArrayObj.mqh>
#include <Arrays\List.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDictionaryEntryBase : public CObject
  {
protected:
   string            m_key;
public:
                     CDictionaryEntryBase(string key);
                    ~CDictionaryEntryBase();
   void              Key(const string key);
   string            Key(void) const;
   virtual string    TypeName(void) const;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDictionaryEntryBase::CDictionaryEntryBase(string key) : m_key(key)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDictionaryEntryBase::~CDictionaryEntryBase(void)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDictionaryEntryBase::Key(const string key)
  {
   m_key=key;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CDictionaryEntryBase::Key(void) const
  {
   return m_key;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CDictionaryEntryBase::TypeName(void) const
  {
   return NULL;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
class CDictionaryEntry : public CDictionaryEntryBase
  {
protected:
   T                 m_value;
public:
                     CDictionaryEntry(string key,T value);
                    ~CDictionaryEntry(void);
   virtual int       Compare(const CObject *node,const int mode=0) const;
   virtual string    TypeName(void) const;
   bool              Value(string key,T value);
   T                 Value(string key);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
CDictionaryEntry::CDictionaryEntry(string key,T value) : CDictionaryEntryBase(key)
  {
   m_value=value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
CDictionaryEntry::~CDictionaryEntry(void)
  {
   CObject *object=dynamic_cast<CObject*>(m_value);
   if(CheckPointer(object)==POINTER_DYNAMIC)
      delete object;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
int CDictionaryEntry::Compare(const CObject *node,const int mode=0) const
  {
   const CDictionaryEntryBase *node_entry=node;
   string str1 = Key()+TypeName();
   string str2 = node_entry.Key()+node_entry.TypeName();
   return StringCompare(str1,str2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
string CDictionaryEntry::TypeName(void) const
  {
   return typename(T);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool CDictionaryEntry::Value(string key,T value)
  {   
   CObject *m_object=dynamic_cast<CObject*>(m_value);   
   if(CheckPointer(m_object)==POINTER_DYNAMIC)
     {
      CObject *object=dynamic_cast<CObject*>(value);
      if(CheckPointer(object) && m_object!=object)
        {
         delete m_object;
         m_object=object;
        }
     }
   else m_value=value;
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
T CDictionaryEntry::Value(string key)
  {
   return m_value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDictionary : public CArrayObj
  {
protected:
   int               m_initial_capacity;
   double            m_resize_threshold;
   int               m_multiplier;
public:
                     CDictionary(int initial_capacity=500,double resize_threshold=0.6,int multiplier=3);
                    ~CDictionary(void);
   bool              Add(CDictionaryEntryBase *entry);
   template<typename T>
   bool              Contains(string key);
   template<typename T>
   bool              Delete(string key);
   template<typename T>
   T                 Get(string key);
   template<typename T>
   bool              Get(string key,T &value);
   bool              Reset();
   template<typename T>
   bool              Set(string key,T value);
protected:
   bool              Allocate(void);
   uint              Hash(string str);
   int               Index(uint key);
   bool              Recalculate();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDictionary::CDictionary(int initial_capacity=500,double resize_threshold=0.6,int multiplier=3) : m_initial_capacity(initial_capacity),
                                                                                                  m_resize_threshold(resize_threshold),
                                                                                                  m_multiplier(multiplier)
  {
   Reset();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDictionary::~CDictionary(void)
  {
   if(m_free_mode)
      for(int i=0;i<m_data_max;i++)
         if(CheckPointer(m_data[i]))
            delete m_data[i];
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDictionary::Add(CDictionaryEntryBase *entry)
  {
   if(CheckPointer(entry))
     {
      int index=Index(Hash(entry.Key()+entry.TypeName()));
      CList *list=m_data[index];
      if(CheckPointer(list))
        {
         CDictionaryEntryBase *result=list.Search(entry);
         if(CheckPointer(result))
           {
            list.Delete(list.IndexOf(result));
            m_data_total--;
           }
        }
      else
        {
         list=new CList();
         m_data[index]=list;
        }
      if(list.Add(entry)>=0)
        {
         list.Sort(0);
         m_data_total++;
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDictionary::Allocate(void)
  {
   if(m_data_total>m_data_max*m_resize_threshold)
     {
      int new_size= ArrayResize(m_data,m_data_max*m_multiplier);
      if(new_size!=m_data_max*m_multiplier)
         return false;
      m_data_max=new_size;
      return Recalculate();
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool CDictionary::Contains(string key)
  {
   bool res=false;
   T value=NULL;
   int index=Index(Hash(key+typename(T)));
   CList *list=m_data[index];
   if(CheckPointer(list))
     {
      CDictionaryEntryBase *model=new CDictionaryEntry<T>(key,value);
      if(CheckPointer(list.Search(model)))
         res=true;
      delete model;
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool CDictionary::Delete(string key)
  {
   bool res=false;
   T value=NULL;
   int index=Index(Hash(key+typename(T)));
   CList *list=m_data[index];
   if(CheckPointer(list))
     {
      CDictionaryEntryBase *model=new CDictionaryEntry<T>(key,value);
      CDictionaryEntryBase *result=list.Search(model);
      if(CheckPointer(result))
        {
         list.Delete(list.IndexOf(result));
         res=true;
        }
      delete model;
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool CDictionary::Get(string key,T &value)
  {
   bool res=false;
   int index=Index(Hash(key+typename(T)));
   CList *list=m_data[index];
   if(CheckPointer(list))
     {
      CDictionaryEntryBase *model=new CDictionaryEntry<T>(key,value);
      CDictionaryEntryBase *result=list.Search(model);
      if(CheckPointer(result))
        {
         CDictionaryEntry<T>*model_entry=result;
         value=model_entry.Value(key);
         res=true;
        }
      delete model;
     }
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
T CDictionary::Get(string key)
  {
   T value;
   Get(key,value);
   return value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint CDictionary::Hash(string str)
  {
   uint fnv_prime=16777619;
   uint offset_basis=2166136261;
   uint hash=offset_basis;
   uchar arr[];
   StringToCharArray(str,arr);
   uint len=StringLen(str);
   for(uint n=0; n<len; n++)
     {
      hash^= arr[n];
      hash =(hash*fnv_prime);
     }
   return hash%INT_MAX;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CDictionary::Index(uint key)
  {
   return int(key % m_data_max);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDictionary::Recalculate(void)
  {
   CArrayObj array;
   array.FreeMode(false);
   m_data_total=0;
   int i;
   for(i=0;i<m_data_max;i++)
     {
      CList *list1=m_data[i];
      if(!CheckPointer(list1))
         continue;
      while(list1.Total()!=0)
         array.Add(list1.DetachCurrent());
     }
   for(i=0;i<array.Total();i++)
     {
      CDictionaryEntryBase *entry=array.At(i);
      if(CheckPointer(entry))
        {
         int index=Index(Hash(entry.Key()+entry.TypeName()));
         CList *list2=m_data[index];
         if(!CheckPointer(list2))
           {
            list2=new CList();
            m_data[index]=list2;
           }
         if(list2.Add(entry)>=0)
           {
            list2.Sort(0);
            m_data_total++;
           }
        }
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDictionary::Reset(void)
  {
   if(m_data_total>0)
      for(int i=0;i<m_data_max;i++)
         if(CheckPointer(m_data[i]))
            delete m_data[i];
   return Resize(m_initial_capacity);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool CDictionary::Set(string key,T value)
  {
   if(Allocate())
     {
      int index=Index(Hash(key+typename(T)));
      CDictionaryEntryBase *model=new CDictionaryEntry<T>(key,value);
      CList *list=m_data[index];
      if(CheckPointer(list))
        {
         CDictionaryEntryBase *result=list.Search(model);
         if(CheckPointer(result))
           {
            if (list.Delete(list.IndexOf(result)))
               m_data_total--;
            else
            {
               delete model;
               return false;
            }
           }
         if(list.Add(model)>=0)
           {
            list.Sort(0);
            m_data_total++;
            return true;
           }
        }
      else
        {
         list=new CList();
         m_data[index]=list;
         if(list.Add(model)>=0)
           {
            list.Sort(0);
            m_data_total++;
           }
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
