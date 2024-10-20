#include "../../includes/linkstate.h"
#include "../../includes/packet.h"
interface LinkStateRouting{
    command void listRoute(uint8_t srcNode);
    command void printLinkState();
    command error_t receiveHandler(pack myMsg);
}