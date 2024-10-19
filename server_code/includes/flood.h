#ifndef FLOOD_H
#define FLOOD_H


#include "protocol.h"
#include "channels.h"
#include "packet.h"

enum{
	// Flood source
	FLOODING_HEADER_LENGTH = 2,
	FLOODING_MAX_PAYLOAD_SIZE = PACKET_MAX_PAYLOAD_SIZE - FLOODING_HEADER_LENGTH
};


typedef nx_struct floodPack{
	nx_uint16_t floodSource;
	nx_uint8_t payload[FLOODING_MAX_PAYLOAD_SIZE];
}floodPack;

typedef struct floodCache{
	uint16_t seq;
	uint16_t floodSource;
}floodCache;

#endif
