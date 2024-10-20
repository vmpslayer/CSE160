#ifndef LINKSTATE_H
#define LINKSTATE_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"

enum{
    MAX_NEIGHBORS = 20,
};

typedef struct LinkState{
    nx_uint8_t address; // Identifier for node
    uint16_t neighbors[MAX_NEIGHBORS]; // For calculations, X = total packets received
    uint16_t neighborCount; // For calculations, Y = total packets sent
} LinkState;

void logLSRoute(LinkState *route){
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++){
        dbg(GENERAL_CHANNEL, "Node Address: %hhu    Neighbors: %hhu     Neighbor Count: %hhu\n", route->address, route->neighbors[i], route->neighborCount);
    }
};

#endif
