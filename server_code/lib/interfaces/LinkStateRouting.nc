#include "../../includes/linkstate.h"
#include "../../includes/packet.h"
interface LinkStateRouting{
    command error_t initLinkState();
    // command void listRoute(uint8_t srcNode);
    // command void printLinkState();
    command void receiveHandler(pack myMsg);
}