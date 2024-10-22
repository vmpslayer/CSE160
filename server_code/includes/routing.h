#ifndef ROUTING_H
#define ROUTING_H

typedef struct Routing{
    nx_uint8_t address; // Identifier for node
    uint8_t cost; // Cost it takes (in hops)
    uint8_t altCost; // Cost it takes (in hops) but with an ALTERNATE ROUTE BROTHER
    nx_uint8_t nextHop; // NEXT HOP FOR EACH ADDRESS
    nx_uint8_t altNextHop; // Idenfier for node that has alternate route
} Routing;

void logRoute(Routing *route){
    uint8_t i;

    for(i = 0; i < MAX_NEIGHBORS; i++){
        dbg(GENERAL_CHANNEL, "Node Address: %hhu     Neighbor Count: %hhu\n", route->address, route->cost);
    }
};

#endif