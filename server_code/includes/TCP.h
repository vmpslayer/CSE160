#ifndef TCP_H
#define TCP_H

typedef nx_struct TCP{
    nx_uint16_t srcPort;
    nx_uint16_t destPort;
    nx_uint32_t seq;
    nx_uint32_t ack;
    nx_uint8_t flags; // SYN, ACK, FIN (never carry payload data)
    nx_uint16_t adwindow;
} TCP;

#endif