#ifndef NEIGHBOR_H
#define NEIGHBOR_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 20,
};

typedef struct Neighbor{
    nx_uint8_t address; // Identifier for node
    uint16_t pktReceived; // For calculations, X = total packets received
    uint16_t pktSent; // For calculations, Y = total packets sent
    float qol;
} Neighbor;

void logNeighbor(Neighbor *neighbor){
	dbg(GENERAL_CHANNEL, "Node Address: %hhu Packets Received: %hhu Packets Sent: %hhu\n",
	neighbor->address, neighbor->pktReceived, neighbor->pktSent);
};

#endif