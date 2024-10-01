#include "../../includes/device.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void findNeighbor();
    command void checkNeighbor();
    command void addNeighbor(uint8_t node);
    command void removeNeighbor(uint8_t node);
}   