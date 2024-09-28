
#include "../../includes/Neighbor.h"
#include "../../includes/packet.h"

interface NeighborDiscovery{
    command void findNeighbor();
    command void listNeighborhood();
}