#ifndef LINKSTATE_H
#define LINKSTATE_H

#include "packet.h"
#include "protocol.h"
#include "channels.h"


typedef struct LinkState{
    nx_uint8_t address; // Identifier for node
    uint16_t neighbors[MAX_NEIGHBORS];
    uint16_t cost; // Amount of hops it takes to get to node
} LinkState;

void logLSRoute(LinkState *route){
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++){
        dbg(GENERAL_CHANNEL, "Node Address: %hhu     Neighbor Count: %hhu\n", route->address, route->cost);
    }
};

#endif
