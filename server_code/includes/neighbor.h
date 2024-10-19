#ifndef NEIGHBOR_H
#define NEIGHBOR_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 20,
};

typedef nx_struct Neighbor{
    nx_uint8_t address; // Identifier for node
    nx_uint16_t pktReceived; // For calculations, X = total packets received
    nx_uint16_t pktSent; // For calculations, Y = total packets sent
    nx_uint16_t qol; // Quality of link = received packets / sent packets
} Neighbor;

void logNeighbor(Neighbor *neighbor){
	dbg(GENERAL_CHANNEL, "Node Address: %hhu Packets Received: %hhu Packets Sent: %hhu\n",
	neighbor->address, neighbor->pktReceived, neighbor->pktSent);
};

#endif
