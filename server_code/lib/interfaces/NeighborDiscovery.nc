#include "../../includes/neighbor.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void initNeighborDisco();
    command void addNeighbor(uint8_t node);
    command void removeNeighbor(uint8_t node);
    command error_t receiveHandler(pack msg);
    event void updateListener(Neighbor* table, uint8_t length);
}   