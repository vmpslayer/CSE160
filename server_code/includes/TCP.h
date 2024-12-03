#ifndef TCP_H
#define TCP_H

#include "packet.h"

enum flag_type{
    SYN,
    SYNACK,
    ACK,
    FIN,
    DATA
};

enum{
    TCP_HEADER_LENGTH = 11,
	TCP_MAX_PAYLOAD_SIZE = PACKET_MAX_PAYLOAD_SIZE - TCP_HEADER_LENGTH,
};

typedef struct TCP{
    nx_uint16_t srcPort;
    nx_uint16_t destPort;
    nx_uint16_t seq;
    nx_uint16_t ack;
    enum flag_type flags; // SYN, ACK, SYNACK, FIN (never carry payload data)
    uint8_t payload[TCP_MAX_PAYLOAD_SIZE];
    uint16_t adwindow;
} TCP;

#endif