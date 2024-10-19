#include "../../includes/neighbor.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void findNeighbor();
    command void addNeighbor(uint8_t node);
    command void removeNeighbor(uint8_t node);
}   