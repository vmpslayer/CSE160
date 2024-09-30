
#include "../../includes/Neighbor.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void findNeighbor();
    command void listNeighborhood();
    command void addNeighbor(uint8_t node, uint8_t neighbor);
}