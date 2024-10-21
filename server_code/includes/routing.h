#ifndef ROUTING_H
#define ROUTING_H

typedef struct Routing{
    nx_uint8_t address; // Identifier for node
    nx_uint8_t altAddress;
    uint8_t cost[MAX_NEIGHBORS];
    uint8_t altCost[MAX_NEIGHBORS];
} Routing;

void logRoute(ROUTING *route){
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++){
        dbg(GENERAL_CHANNEL, "Node Address: %hhu     Neighbor Count: %hhu\n", route->address, route->cost);
    }
};

#endif