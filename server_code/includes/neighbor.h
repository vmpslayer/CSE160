#ifndef NEIGHBOR_H
#define NEIGHBOR_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 10,
};

typedef struct Neighbor{
    nx_uint16_t address; // Identifier for node
    uint8_t pktReceived; // For calculations, X = total packets received
    uint8_t pktSent; // For calculations, Y = total packets sent
    float qol; // Calculated for quality of life (quality of link hahaha)
} Neighbor;

void logNeighbor(Neighbor *neighbor){
	dbg(GENERAL_CHANNEL, "Node Address: %hhu Packets Received: %hhu Packets Sent: %hhu\n",
	neighbor->address, neighbor->pktReceived, neighbor->pktSent);
};

#endif
