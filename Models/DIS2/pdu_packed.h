#ifndef PDU_PACKED_H_
#define PDU_PACKED_H_

#include <algorithm>
#include <iostream>

namespace dis
{

class Packed
{
public:
	static unsigned char**& offset()
	{
		static unsigned char **ptr;
		return ptr;
	}
private:
	unsigned char data[1500];
	unsigned char *data_end;
public:
	template<class T> class Type
	{
		unsigned char* const ptr;
public:
		Type() :
			ptr(*Packed::offset())
		{
			*Packed::offset()+=sizeof(T);
		}
		Type(unsigned char *& offset) :
			ptr(offset)
		{
			offset+=sizeof(T);
		}
		operator T() const
		{
			union
			{
				T var;
				unsigned char c[1];
			} silly_name;
			std::reverse_copy(ptr, ptr+sizeof(silly_name.var), silly_name.c);
			return silly_name.var;
		}
		T operator=(T var)
		{
			unsigned char *c=reinterpret_cast<unsigned char*>(&var);
			std::reverse_copy(c, c+sizeof(var), ptr);
			return var;
		}
		Type<T>& operator=(const Type<T>& rhs)
		{
			T v1=rhs;
			this->operator=(v1);
			return *this;
		}
		template<class U> Type<T>& operator=(const Type<U>& rhs)
		{
			U v1=rhs;
			this->operator=(static_cast<T>(v1));
			return *this;
		}
		friend std::istream& operator>>(std::istream& is, Type<T>& var)
		{
			double v;
			is>>v;
			var=static_cast<T>(v);
			return is;
		}
	};
	Packed() :
		data_end(data)
	{
		Packed::offset()=&data_end;
	}
	virtual ~Packed()
	{
	}
	unsigned int size()
	{
		return static_cast<unsigned int>(data_end-data);
	}
	const unsigned char *begin()
	{
		return data;
	}
	virtual const unsigned char *end()
	{
		return data_end;
	}
	void reload(const char *begin)
	{
		std::copy(begin, begin+size(), data);
	}
	void reload(const char *begin, const char *end)
	{
		std::copy(begin, end, data);
	}
	void reload(const unsigned char *begin)
	{
		std::copy(begin, begin+size(), data);
	}
	void reload(const unsigned char *begin, const unsigned char *end)
	{
		std::copy(begin, end, data);
	}
};

// Windows does nothave "stdint.h"
#include <boost/cstdint.hpp>
using namespace boost;

#if 0
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned long uint32_t;
typedef signed char int8_t;
typedef short int16_t;
typedef int int32_t;
#endif

typedef float float32_t;
typedef double float64_t;

typedef Packed::Type<uint8_t> uint8_p;
typedef Packed::Type<uint16_t> uint16_p;
typedef Packed::Type<uint32_t> uint32_p;
typedef Packed::Type<int8_t> int8_p;
typedef Packed::Type<int16_t> int16_p;
typedef Packed::Type<int32_t> int32_p;
typedef Packed::Type<float> float32_p;
typedef Packed::Type<double> float64_p;

struct PDU : public Packed
{
	struct
	{
		uint8_p protocol_version;
		uint8_p exercise_id;
		uint8_p pdu_type;
		uint8_p protocol_family;
		uint32_p time_stamp;
		uint16_p length;
		uint16_p padding;
	} header;
	struct EntityID
	{
		uint16_p site;
		uint16_p application;
		uint16_p entity;
	};
	struct DisEnumType
	{
		uint8_p kind;
		uint8_p domain;
		uint16_p country;
		uint8_p category;
		uint8_p subcategory;
		uint8_p specific;
		uint8_p extra;
	};
};

struct EntityStatePDU : public PDU
{
	enum FORCE_ID
	{	OTHER, FRIENDLY, OPPOSING, NEUTRAL};
	unsigned int size()
	{
		return static_cast<unsigned int>(end()-begin());
	}
	const unsigned char *end()
	{
		uint8_t n=num_articulation_params;
		return PDU::begin()+144+n*16;
	}
	EntityStatePDU()
	{
		header.pdu_type=1;
		num_articulation_params=0;
	}
	struct ArtParam
	{
		int8_p type_designator;
		int8_p change;
		int16_p ID_attached_to;
		int32_p parameter_type;
		float64_p parameter_value;
	};
	EntityID entity_id;
	uint8_p force_id;
	uint8_p num_articulation_params;
	DisEnumType entity_type;
	DisEnumType alt_entity_type;
	float32_p velocity[3];
	float64_p location[3];
	float32_p orientation[3];
	int32_p entity_appearance;
	int8_p dead_reckoning_algorithm;
	int8_p dead_reckoning_params[15];
	float32_p acceleration[3];
	float32_p angular_velocity[3];
	int8_p character_set;
	int8_p entity_marking[11];
	int32_p capabilities;
	ArtParam articulation_parameter[78];
};

struct StartResumePDU : public PDU
{
	struct Time
	{
		uint32_p hour;
		uint32_p time_past_the_hour;
	};
	EntityID originating_entity_id;
	EntityID receiving_entity_id;
	Time real_world_time;
	Time simulation_time;
	uint32_t request_id;
	StartResumePDU()
	{
		header.pdu_type=13;
	}
};

template<class T> struct SignalPDU : public PDU
{
	EntityID entity_id;
	uint16_p radio_id;
	uint16_p encoding_scheme;
	uint16_p TDL_type;
	uint32_p sample_rate;
	uint16_p data_length;
	uint16_p samples;
	T data;
	SignalPDU()
	{
		header.pdu_type=26;
	}
};

} //namespace dis
#endif
