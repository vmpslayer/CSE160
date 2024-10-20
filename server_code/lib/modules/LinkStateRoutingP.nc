module LinkStateRoutingP{
    provides interface LinkStateRouting;

    uses interface Timer<TMilli> as linkStateTimer;
    uses interface NeighborDiscovery as NeighborDiscovery;
    uses interface Flooding as Flooding;
}
implementation{
    // Initialization:
    // N’ = {u} // Compute least cost path from u to all other nodes
    // For all nodes a
    // If a adjacent to u //u initially knows direct-path-cost to direct neighbors
    // Then D(a) = Cu,a // but it may not be the minimum cost!
    //         Else D(a) = ∞
    // Loop:
    //     Find a not in N’ such that D(a) is a minimum
    //     Add a to N’
    //     Update D(b) for all b adjacent to a and not in N’:
    //         D(b) = min(D(b), D(a) + Ca,b)
    //     // new least-path-cost to b is either old least-cost-path to 
    // b or known least-cost-path to a plus direction-cost from a to b
    // Until all nodes in N’
    
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    // Result of the algorithm should be a routing table containing the next-hop neighbor to send to for each destination address.
    command void LinkStateRouting.listRouteTable(uint8_t srcNode){
        // List forwarding table for certain node
    }

    command void LinkStateRouting.receiveHandler(pack myMsg){
        // Listener Handler
    }
}