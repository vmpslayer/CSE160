module ChatP{
    provides interface Chat;

    uses interface Transport;
}
implementation{
    command error_t Chat.hello(uint8_t username, nx_uint8_t clientPort){
        dbg(CHAT_CHANNEL, "HELLO: Initializing Handshake\n");

        nx_uint8_t serverPort = 80;
        nx_uint8_t serverAddr = 1;

        if(call Transport.initTransportclient(serverAddr, clientPort, serverPort) == SUCCESS){
            dbg(CHAT_CHANNEL, "HELLO: Handshake initialized successfully\n");
            return SUCCESS;
        }
        else{
            dbg(CHAT_CHANNEL, "HELLO: Failed to initialize handshake\n");
            return FAIL;
        }
    }

    command error_t Chat.message(uint8_t msg){
        dbg(CHAT_CHANNEL, "MESSAGE: Broadcasting message\n");

        nx_uint8_t destPort = 80;
        nx_uint8_t destAddr = 1;
        nx_uint8_t srcPort = 101;

        if(call Transport.writeMsg(TOS_NODE_ID, srcPort, destAddr, destPort) == SUCCESS){
            dbg(CHAT_CHANNEL, "MESSAGE: Broadcast SUCCESSFUL\n");
        }
        else{
            dbg(CHAT_CHANNEL, "MESSAGE: Broadcast FAILED\n");
        }
    }

    command error_t Chat.whisper(uint8_t username, uint8_t msg){
        dbg(CHAT_CHANNEL, "WHSIPER: Sending private message to %s\n", username);
    }

    command error_t Chat.list(){
        dbg(CHAT_CHANNEL, "LIST: Listing all users connected\n");
    }
}   