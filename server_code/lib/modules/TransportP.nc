#include "../../includes/TCP.h"
#include "../../includes/socket.h"

module TransportP{
    provides interface Transport;

    uses interface Timer<TMilli> as transportTimer;
    uses interface LinkStateRouting;
}
implementation{
    socket_store_t connections[MAX_NUM_OF_SOCKETS];
    Routing forwardingTable[MAX_NEIGHBORS];
    pack pkt;

    event void LinkStateRouting.updateListener(Routing* table, uint8_t length){
        memcpy(forwardingTable, table, length * sizeof(Routing));
    }

    command error_t Transport.initTransport(){
        call transportTimer.startOneShot(1000);
        return SUCCESS;
    }

    event void transportTimer.fired(){
        socket_t socket;

        socket = call Transport.socket();
        dbg(TRANSPORT_CHANNEL, "SUCCESS: Transport Started\n");
    }

    command socket_t Transport.socket(){
        // Get a socket if there is one available
        // Look for closed socket
        // Then, return that socket
        uint8_t i;

        for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
            if(connections[i].state == CLOSED){
                return i;
            }
        }
        return NULL;
    }
    command error_t Transport.bind(socket_t fd, socket_addr_t *addr){
        // Bind socket with address
        if(connections[fd].state == CLOSED){
            // SUCCESS if you can bind to socket
            connections[fd].src = addr->port;
            connections[fd].dest = *addr;
            return SUCCESS;
        }
        return FAIL;
    }
    command socket_t Transport.accept(socket_t fd){
        uint8_t i;
        if(connections[fd].state == LISTEN){
            for(i = 0; i < MAX_NUM_OF_SOCKETS; i++){
                if(connections[i].state == CLOSED){
                    connections[i] = connections[fd];
                    connections[i].state = ESTABLISHED;
                    return i;
                }
            }
        }
        return NULL;
    }
    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen){
        // Change TTL (0) to a value
        // makePack(&pkt, connections[fd].src, connections[fd].dest.port, 0, PROTOCOL_TCP, connections[fd].seq, buff, bufflen)
    }
    command error_t Transport.receive(pack* package){
        uint8_t i = 0;

        // for(int = 0; i < MAX_NUM_OF_SOCKETS; i++){
        //     if(connections[i].state == LISTEN && connections[i].src == package->dest && connections[i].dest.port == package->src){
                
        //     }
        // }
    }
    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen){

    }
    command error_t Transport.connect(socket_t fd, socket_addr_t * addr){
        if(connections[fd].state != CLOSED){
            return FAIL;
        }

        TCP synPkt;
        synPkt.srcPort = connections[fd].src;
        synPkt.destPort = addr->port;
        synPkt.seq = connections[fd].seq;
        synPkt.ack = 0;
        synPkt.flags = SYN;

        // Change TTL (0) to a value
        makePack(&pkt, connections[fd].src, addr->port, 0, PROTOCOL_TCP, connections[fd].seq, (uint8_t)*&syn, (sizeof(TCP)));
    }
    command error_t Transport.close(socket_t fd){
        if(connections[fd].state == ESTABLISHED){
            connections[fd].state = CLOSED;
            return SUCCESS;
        }
        return FAIL;
    }
    command error_t Transport.release(socket_t fd){
        
    }
    command error_t Transport.listen(socket_t fd){
        // Connection, establish it on a random socket
        // Traffic from one port to
        if(connections[fd].state == CLOSED){
            connections[fd].state = LISTEN;
            return SUCCESS;
        }
        return FAIL;
    }
    command error_t Transport.testServer(nx_uint8_t src, nx_uint8_t srcPort){
        if(call Transport.initTransport() == SUCCESS){
            call Transport.bind();
        }
        return SUCCESS;
    }
    command error_t Transport.testClient(nx_uint8_t src, nx_uint8_t srcPort, nx_uint8_t dest, nx_uint8_t destPort){
        return SUCCESS;
    }
    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }
}