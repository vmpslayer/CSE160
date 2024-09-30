#include "../../includes/device.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void findNeighbor();
    command void listHood();
    command void checkNeighbor();
    command void addNeighbor(uint8_t node, uint8_t neighbor);
    command void removeNeighbor(uint8_t node, uint8_t neighbor);
}