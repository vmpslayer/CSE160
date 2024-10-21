#ifndef ROUTING_H
#define ROUTING_H

typedef struct Routing{
    nx_uint8_t address; // Identifier for node
    nx_uint8_t altAddress; // Idenfier for node that has alternate route
    uint8_t cost[MAX_NEIGHBORS]; // Cost it takes (in hops)
    uint8_t altCost[MAX_NEIGHBORS];
    nx_uint8_t nextHop;
} Routing;

void logRoute(Routing *route){
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++){
        dbg(GENERAL_CHANNEL, "Node Address: %hhu     Neighbor Count: %hhu\n", route->address, route->cost);
    }
};

#endif