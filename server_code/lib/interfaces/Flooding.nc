#include "../../includes/packet.h"

interface Flooding{
    command error_t flood(pack msg, uint16_t dest);
}